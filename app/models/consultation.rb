# frozen_string_literal: true

class Consultation < ApplicationRecord
  class AddNeighbourAddressesError < StandardError; end

  include GeojsonFormattable

  belongs_to :planning_application
  delegate :local_authority, to: :planning_application

  with_options dependent: :destroy do
    has_many :consultees, extend: ConsulteesExtension
    has_many :neighbours
    has_many :site_visits
  end

  with_options through: :consultees do
    has_many :consultee_emails, source: :emails, class_name: "Consultee::Email"
    has_many :consultee_responses, source: :responses, class_name: "Consultee::Response"
  end

  with_options through: :neighbours do
    has_many :neighbour_letters
    has_many :neighbour_responses
  end

  validate do
    next unless validation_context == :send_consultee_emails
    next if consultees.none?

    errors.add(:consultees, :blank) if consultees.none_selected?
  end

  accepts_nested_attributes_for :consultees, :neighbours

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    complete: "complete"
  }

  before_update :audit_letter_copy_sent!, if: :letter_copy_sent_at_changed?

  format_geojson_epsg :polygon_geojson

  def send_consultee_emails(attributes)
    self.attributes = attributes
    return false unless save(context: :send_consultee_emails)

    SendConsulteeEmailsJob.perform_now(
      self,
      consultees.selected,
      consultee_email_subject,
      consultee_email_body
    )

    start_deadline

    Audit.create!(
      planning_application_id: planning_application_id,
      user: Current.user,
      activity_type: "consultee_emails_sent"
    )
  end

  def start_deadline
    update!(end_date: end_date_from_now, start_date: start_date || 1.business_day.from_now)
  end

  def end_date_from_now
    # Letters are printed at 5:30pm and dispatched the next working day (Monday to Friday)
    # Second class letters are delivered 2 days after they’re dispatched.
    # Royal Mail delivers from Monday to Saturday, excluding bank holidays.
    1.business_day.from_now + 21.days
  end

  def days_left
    (end_date - Time.zone.now).seconds.in_days.round
  end

  def neighbour_letters_status
    if neighbour_letters.failed.present?
      "failed"
    elsif neighbour_letters.sent.present?
      "complete"
    elsif neighbours.present?
      "in_progress"
    else
      "not_started"
    end
  end

  def neighbour_responses_status
    return "not_started" if end_date.blank?

    if complete?
      "complete"
    elsif neighbour_responses.present?
      "in_progress"
    else
      "not_started"
    end
  end

  def consultee_emails_status
    if consultees.any?(&:failed?)
      "failed"
    elsif consultees.any?(&:consulted?) && consultees.none?(&:sending?)
      "complete"
    elsif consultees.present?
      "in_progress"
    else
      "not_started"
    end
  end

  def consultee_responses_status
    return "not_started" if end_date.blank?

    if complete?
      "complete"
    elsif consultee_responses.present?
      "in_progress"
    else
      "not_started"
    end
  end

  def consultee_email_subject
    super.presence || I18n.t("subject", scope: "consultee_emails")
  end

  def consultee_email_body
    super.presence || I18n.t("body", scope: "consultee_emails")
  end

  def neighbour_letter_header
    I18n.t("neighbour_letter_header.#{planning_application.application_type.name}",
           closing_date: end_date_from_now.to_date.to_fs)
  end

  def neighbour_letter_body
    I18n.t("neighbour_letter_template.#{planning_application.application_type.name}",
           expiry_date: planning_application.expiry_date.to_date.to_fs,
           address: planning_application.full_address,
           council: local_authority.short_name,
           applicant_name: "#{planning_application.applicant_first_name} #{planning_application.applicant_last_name}",
           description: planning_application.description,
           reference: planning_application.reference,
           closing_date: end_date_from_now.to_date.to_fs,
           rear_wall: planning_application&.proposal_measurement&.depth,
           max_height: planning_application&.proposal_measurement&.max_height,
           eaves_height: planning_application&.proposal_measurement&.eaves_height,
           current_user: Current.user.name,
           council_address: I18n.t("council_addresses.#{local_authority.subdomain}"),
           application_link:)
  end

  def neighbour_letter_content
    "# #{neighbour_letter_header}\n\n#{neighbour_letter_body}"
  end

  def neighbour_letter_text
    super.presence || neighbour_letter_content
  end

  def site_visit
    site_visits.by_created_at_desc.first
  end

  def neighbour_responses_by_summary_tag
    neighbour_responses.group(:summary_tag).order(:summary_tag).count
  end

  def selected_neighbour_addresses
    neighbours.select(&:persisted?).select(&:selected?).map(&:address)
  end

  def selected_neighbours
    neighbours.select(&:persisted?).select(&:selected?)
  end

  def publicity_active?
    return false unless end_date

    end_date > Time.zone.now || (end_date.to_date == Time.zone.now.to_date)
  end

  def polygon_geojson=(value)
    self.polygon_search = geometry_collection(value) if value.present?
    super
  end

  def polygon_fill_colour
    "#{polygon_colour}20"
  end

  def polygon_search_and_boundary_geojson
    return unless polygon_search
    return polygon_search_geojson unless planning_application.boundary_geojson

    boundary_geojson = JSON.parse(planning_application.boundary_geojson)
    feature_collection_geojson = polygon_search_geojson

    case boundary_geojson["type"]
    when "Feature"
      feature_collection_geojson["features"] << boundary_geojson
    when "FeatureCollection"
      feature_collection_geojson["features"].concat(boundary_geojson["features"])
    else
      raise ArgumentError,
            "Invalid GeoJSON type. Expected 'Feature' or 'FeatureCollection', got #{boundary_geojson['type']}."
    end

    feature_collection_geojson
  end

  def not_started?
    !started?
  end

  def started?
    neighbour_responses.present? && end_date.present?
  end

  def complete?
    started? && end_date < Time.zone.now
  end

  def application_link
    "#{local_authority.applicants_url}/planning_applications/#{planning_application_id}"
  end

  private

  def audit_letter_copy_sent!
    Audit.create!(
      planning_application_id:,
      user: Current.user,
      activity_type: "neighbour_letter_copy_mail_sent",
      audit_comment:
        "Neighbour letter copy sent by email to #{planning_application.applicant_and_agent_email.join(', ')}"
    )
  end

  def factory
    @factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def geometry_collection(geojson)
    parsed = JSON.parse(geojson)["EPSG:3857"]
    decoded = RGeo::GeoJSON.decode(parsed)
    geometries = decoded.map(&:geometry)

    factory.collection(geometries)
  end

  def polygon_search_geojson
    features = polygon_search.map do |geometry|
      {
        "type" => "Feature",
        "geometry" => RGeo::GeoJSON.encode(geometry),
        "properties" => { color: polygon_colour }
      }
    end

    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end
end
