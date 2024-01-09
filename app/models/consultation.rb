# frozen_string_literal: true

class Consultation < ApplicationRecord
  class AddNeighbourAddressesError < StandardError; end

  include DateValidateable

  EMAIL_REASONS = %w[send resend reconsult].freeze
  EMAIL_PLACEHOLDER = /\{\{\s*([a-z][_a-z0-9]+)\s*\}\}/
  EMAIL_PLACEHOLDERS = %w[
    name reference address description link closing_date
    signatory_name signatory_job_title local_authority
  ].freeze

  attribute :consultee_message_subject, :string, default: -> { default_consultee_message_subject }
  attribute :consultee_message_body, :string, default: -> { default_consultee_message_body }

  attribute :email_reason, :string, default: "send"
  attribute :resend_message, :string
  attribute :reconsult_message, :string
  attribute :reconsult_date, :date, default: -> { Date.current + 21.days }

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

  with_options on: :send_consultee_emails do
    validates :consultee_message_subject, presence: true
    validates :consultee_message_body, presence: true
    validates :email_reason, inclusion: {in: EMAIL_REASONS}

    with_options if: :reconsult? do
      validates :reconsult_message, presence: true
      validates :reconsult_date, presence: true, date: {on_or_after: ->(c) { Date.current + 7.days }}
    end

    validate do
      errors.add(:planning_application, :invalidated) if planning_application.invalidated?
      errors.add(:planning_application, :not_started) if planning_application.not_started?
      errors.add(:planning_application, :not_public) unless planning_application.make_public?
      errors.add(:consultees, :blank) if consultees.none_selected?

      unknown_placeholders(consultee_message_subject) do |placeholder|
        errors.add(:consultee_message_subject, :invalid, placeholder: placeholder)
      end

      unknown_placeholders(consultee_message_body) do |placeholder|
        errors.add(:consultee_message_body, :invalid, placeholder: placeholder)
      end

      if resend?
        unknown_placeholders(resend_message) do |placeholder|
          errors.add(:resend_message, :invalid, placeholder: placeholder)
        end
      end

      if reconsult?
        unknown_placeholders(reconsult_message) do |placeholder|
          errors.add(:reconsult_message, :invalid, placeholder: placeholder)
        end
      end
    end
  end

  accepts_nested_attributes_for :consultees, :neighbours

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    complete: "complete"
  }

  before_update :audit_letter_copy_sent!, if: :letter_copy_sent_at_changed?

  class << self
    def default_consultee_message_subject
      I18n.t("subject", scope: "consultee_emails")
    end

    def default_consultee_message_body
      I18n.t("body", scope: "consultee_emails")
    end
  end

  delegate :default_consultee_message_subject, to: :class
  delegate :default_consultee_message_body, to: :class

  def resend?
    email_reason == "resend"
  end

  def reconsult?
    email_reason == "reconsult"
  end

  def consultee_activity_type
    case email_reason
    when "reconsult"
      "consultees_reconsulted"
    when "resend"
      "consultee_emails_resent"
    else
      "consultee_emails_sent"
    end
  end

  def send_consultee_emails(attributes)
    return false unless update(attributes, :send_consultee_emails)

    unless start_date?
      start_deadline
    end

    if reconsult?
      extend_deadline(reconsult_date)
    end

    enqueue_send_consultee_email_jobs

    Audit.create!(
      planning_application_id: planning_application_id,
      user: Current.user,
      activity_type: consultee_activity_type
    )
  end

  def start_deadline(now = Time.zone.now)
    update!(end_date: end_date_from(now), start_date: start_date || default_start_date(now))
  end

  def extend_deadline(new_date)
    update!(end_date: [end_date, new_date.end_of_day].max)
  end

  def end_date_from(now = Time.zone.now)
    # Letters are printed at 5:30pm and dispatched the next working day (Monday to Friday)
    # Second class letters are delivered 2 days after they’re dispatched.
    # Royal Mail delivers from Monday to Saturday, excluding bank holidays.
    default_start_date(now).end_of_day + 21.days
  end

  def end_date_from_now
    end_date_from(Time.zone.now)
  end

  def days_left(now = Time.zone.now)
    (end_date - now).seconds.in_days.floor
  end

  def neighbour_letters_status
    if neighbour_letters.failed.present?
      "failed"
    elsif neighbour_letters.sent.present?
      "complete"
    elsif neighbours.with_letters.present?
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
    if consultees.failed?
      "failed"
    elsif consultees.complete?
      "complete"
    elsif consultees.awaiting_responses?
      "awaiting_responses"
    elsif consultees.present?
      "in_progress"
    else
      "not_started"
    end
  end

  def consultee_responses_status
    if consultees.complete?
      "complete"
    elsif consultees.responded?
      "in_progress"
    else
      "not_started"
    end
  end

  def consultee_email_reply_to_id
    super.presence || local_authority.email_reply_to_id
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
    self.polygon_search = geometry_collection(value) if value.present? && JSON.parse(value)["EPSG:3857"].present?
    super
  end

  def polygon_fill_colour
    "#{polygon_colour}20"
  end

  def polygon_search_and_boundary_geojson
    return unless polygon_search
    return polygon_search_geojson unless planning_application.boundary_geojson

    boundary_geojson = planning_application.boundary_geojson
    feature_collection_geojson = polygon_search_geojson

    case boundary_geojson["type"]
    when "Feature"
      feature_collection_geojson["features"] << boundary_geojson
    when "FeatureCollection"
      feature_collection_geojson["features"].concat(boundary_geojson["features"])
    else
      raise ArgumentError,
        "Invalid GeoJSON type. Expected 'Feature' or 'FeatureCollection', got #{boundary_geojson["type"]}."
    end

    feature_collection_geojson
  end

  def not_started?
    !started?
  end

  def started?
    start_date? && start_date < Time.zone.now
  end

  def complete?
    started? && end_date < Time.zone.now
  end

  def application_link
    "#{local_authority.applicants_url}/planning_applications/#{planning_application_id}"
  end

  private

  def unknown_placeholders(string)
    string.to_s.scan(EMAIL_PLACEHOLDER) { yield $1 unless EMAIL_PLACEHOLDERS.include?($1) }
  end

  def replace_placeholders(string, variables)
    string.to_s.gsub(EMAIL_PLACEHOLDER) { variables.fetch($1.to_sym) }
  end

  def default_start_date(now = Time.zone.now)
    1.business_day.since(now).beginning_of_day
  end

  def enqueue_send_consultee_email_jobs
    defaults = {
      signatory_name: local_authority.signatory_name,
      signatory_job_title: local_authority.signatory_job_title,
      local_authority: local_authority.council_name,
      reference: planning_application.reference,
      description: planning_application.description,
      address: planning_application.address,
      link: application_link,
      closing_date: end_date.to_fs
    }

    subject = consultee_message_subject
    body = consultee_message_body
    divider = "\n\n---\n\n"

    if reconsult?
      body = reconsult_message + divider + body
      defaults[:closing_date] = reconsult_date.to_fs
    elsif resend? && resend_message.present?
      body = resend_message + divider + body
    end

    consultees.selected.each do |consultee|
      next if consultee.email_address.blank?

      variables = defaults.merge(name: consultee.name)

      consultee_email = consultee.emails.create!(
        subject: replace_placeholders(subject, variables),
        body: replace_placeholders(body, variables)
      )

      expires_at = \
        if reconsult?
          [end_date, reconsult_date].max
        else
          end_date
        end

      consultee.update!(
        selected: false,
        status: "sending",
        expires_at: expires_at.end_of_day,
        last_email_sent_at: nil,
        last_email_delivered_at: nil
      )

      SendConsulteeEmailJob.perform_later(self, consultee_email)
    end
  end

  def audit_letter_copy_sent!
    Audit.create!(
      planning_application_id:,
      user: Current.user,
      activity_type: "neighbour_letter_copy_mail_sent",
      audit_comment:
        "Neighbour letter copy sent by email to #{planning_application.applicant_and_agent_email.join(", ")}"
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
        "properties" => {color: polygon_colour}
      }
    end

    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end
end
