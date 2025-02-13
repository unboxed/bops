# frozen_string_literal: true

class Consultation < ApplicationRecord
  class AddNeighbourAddressesError < StandardError; end

  include DateValidateable

  EMAIL_REASONS = %w[send resend reconsult].freeze
  EMAIL_PLACEHOLDER = /\{\{\s*([a-z][_a-z0-9]+)\s*\}\}/
  EMAIL_PLACEHOLDERS = %w[
    name application_title_case reference application_short_case
    address description link closing_date
    signatory_name signatory_job_title local_authority
  ].freeze

  DEFAULT_PERIOD = 21
  DEFAULT_PERIOD_DAYS = DEFAULT_PERIOD.days
  EIA_PERIOD = 30
  EIA_PERIOD_DAYS = EIA_PERIOD.days

  STEPS = %w[
    neighbour consultee publicity
  ].freeze

  attribute :consultee_message_subject, :string, default: -> { default_consultee_message_subject }
  attribute :consultee_message_body, :string, default: -> { default_consultee_message_body }

  attribute :deadline_extension, :integer
  attribute :email_reason, :string, default: "send"
  attribute :resend_message, :string
  attribute :reconsult_message, :string
  attribute :consultee_response_period, :integer, default: DEFAULT_PERIOD

  belongs_to :planning_application

  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :neighbour_letter_batches, dependent: :destroy

  with_options to: :planning_application do
    delegate :local_authority
    delegate :environment_impact_assessment, allow_nil: true
  end

  with_options dependent: :destroy do
    has_many :consultees, extend: ConsulteesExtension
    has_many :neighbours
  end

  with_options through: :consultees do
    has_many :consultee_emails, source: :emails, class_name: "Consultee::Email"
    has_many :consultee_responses, source: :responses, class_name: "Consultee::Response"
  end

  with_options through: :neighbours do
    has_many :neighbour_letters
    has_many :neighbour_responses
  end

  with_options as: :owner do
    has_many :reviews, dependent: :destroy
    has_many :neighbour_reviews, -> { neighbour_reviews }, class_name: "Review" # rubocop:disable Rails/HasManyOrHasOneDependent
    has_one :neighbour_review, class_name: "Review" # rubocop:disable Rails/HasManyOrHasOneDependent
  end

  accepts_nested_attributes_for :reviews

  with_options if: :start_date do
    validates :end_date,
      presence: true,
      date: {
        on_or_after: :start_date
      }
  end

  with_options on: :send_consultee_emails do
    validates :consultee_message_subject, presence: true
    validates :consultee_message_body, presence: true
    validates :consultee_response_period, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 99}
    validates :email_reason, inclusion: {in: EMAIL_REASONS}

    with_options if: :reconsult? do
      validates :reconsult_message, presence: true
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

  with_options on: :apply_deadline_extension do
    validates :deadline_extension, presence: true, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 99}
  end

  before_save :apply_deadline_extension, if: -> { deadline_extension.present? }

  accepts_nested_attributes_for :consultees
  accepts_nested_attributes_for :neighbours, reject_if: :neighbour_exists?

  enum :status, %i[
    not_started
    in_progress
    complete
    to_be_reviewed
  ].index_with(&:to_s)

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

  def current_review
    reviews.order(:created_at).last
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

    extend_deadline(consultee_response_required_by) if reconsult?

    enqueue_send_consultee_email_jobs

    Audit.create!(
      planning_application_id: planning_application_id,
      user: Current.user,
      activity_type: consultee_activity_type
    )
  end

  def start_deadline(now = Time.zone.today)
    update!(end_date: [end_date, end_date_from(now)].compact.max, start_date: start_date || default_start_date(now))
  end

  def extend_deadline(new_date)
    new_date = new_date.to_date
    return unless new_date > end_date

    update!(end_date: new_date)
  end

  def end_date_from(now = Time.zone.today)
    # Letters are printed at 5:30pm and dispatched the next working day (Monday to Friday)
    # Second class letters are delivered 2 days after they’re dispatched.
    # Royal Mail delivers from Monday to Saturday, excluding bank holidays.

    effective_period_days = [consultee_response_period.days, period_days].max

    if planning_application.application_type.consultations_skip_bank_holidays?
      Bops::Holidays.days_after_plus_holidays(from_date: default_start_date(now), count: effective_period_days)
    else
      default_start_date(now) + effective_period_days
    end
  end

  def end_date_from_now
    end_date_from(Time.zone.today)
  end

  def letter_closing_date
    end_date_from(Time.next_immediate_business_day(Time.zone.now).to_date)
  end

  def days_left(now = Time.zone.today)
    (end_date - now).floor
  end

  def neighbour_letters_status
    if neighbour_review&.to_be_reviewed?
      "to_be_reviewed"
    elsif neighbour_letters.failed.present?
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
    body = I18n.t("neighbour_letter_header.#{planning_application.application_type.name}")

    defaults = {
      closing_date: letter_closing_date.to_fs,
      default: ""
    }

    replace_placeholders(body, defaults)
  end

  def neighbour_letter_body(body = nil)
    body ||= I18n.t("neighbour_letter_template.consultation.#{planning_application.application_type.name}")

    defaults = {
      expiry_date: planning_application.expiry_date.to_date.to_fs,
      address: planning_application.full_address,
      council: local_authority.short_name,
      applicant_name: "#{planning_application.applicant_first_name} #{planning_application.applicant_last_name}",
      description: planning_application.description,
      reference: planning_application.reference,
      closing_date: letter_closing_date.to_fs,
      rear_wall: planning_application&.proposal_measurement&.depth,
      max_height: planning_application&.proposal_measurement&.max_height,
      eaves_height: planning_application&.proposal_measurement&.eaves_height,
      assigned_officer: assigned_officer,
      council_address: I18n.t("council_addresses.#{local_authority.subdomain}"),
      application_link: public_register_url,
      legislation_title: planning_application.application_type.legislation_title
    }

    replace_placeholders(body, defaults)
  end

  def neighbour_letter_content(body = nil)
    "# #{neighbour_letter_header}\n\n#{neighbour_letter_body(body)}"
  end

  def neighbour_letter_text
    if super.presence&.include?("{{")
      neighbour_letter_content(super.presence)
    else
      super.presence
    end
  end

  def assigned_officer
    planning_application.user.present? ? planning_application.user.name : Current.user.name
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

    end_date >= Time.zone.today
  end

  def polygon_geojson=(value)
    self.polygon_search = geometry_collection(value) if value.present? && JSON.parse(value).present?
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
    start_date? && start_date <= Time.zone.today
  end

  def complete?
    started? && end_date < Time.zone.today
  end

  def application_link
    "#{local_authority.applicants_url}/planning_applications/#{planning_application.reference}"
  end

  def public_register_url
    "#{local_authority.public_register_base_url}/#{planning_application.reference}"
  end

  def period_days
    if environment_impact_assessment.try(:required?)
      Consultation::EIA_PERIOD_DAYS
    else
      Consultation::DEFAULT_PERIOD_DAYS
    end
  end

  def neighbour_review
    neighbour_reviews.max_by(&:created_at)
  end

  def create_neighbour_review!
    neighbour_reviews.create!(status: "complete", assessor: Current.user)
  end

  def consultees_checked?
    reviews&.consultees_checked&.any?
  end

  def create_consultees_review!
    reviews.create!(assessor: Current.user, owner_type: "Consultation", owner_id: id, specific_attributes: {"review_type" => "consultees_checked"}, status: "complete")
  end

  private

  def unknown_placeholders(string)
    string.to_s.scan(EMAIL_PLACEHOLDER) { yield $1 unless EMAIL_PLACEHOLDERS.include?($1) }
  end

  def replace_placeholders(string, variables)
    string.to_s.gsub(EMAIL_PLACEHOLDER) { variables.fetch($1.to_sym) }
  end

  def default_start_date(now = Time.zone.today)
    1.business_day.since(now)
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
      closing_date: consultee_response_required_by.to_fs,
      application_title_case: planning_application.application_title_case,
      application_short_case: planning_application.application_short_case
    }

    subject = consultee_message_subject
    body = consultee_message_body
    divider = "\n\n---\n\n"

    if reconsult?
      body = reconsult_message + divider + body
      defaults[:closing_date] = consultee_response_required_by.to_fs
    elsif resend? && resend_message.present?
      body = resend_message + divider + body
    end

    consultees.selected.each do |consultee|
      next if consultee.email_address.blank?

      variables = defaults.merge(
        name: consultee.name,
        link: consultee.application_link
      )

      consultee_email = consultee.emails.create!(
        subject: replace_placeholders(subject, variables),
        body: replace_placeholders(body, variables)
      )

      consultee.update!(
        selected: false,
        status: "sending",
        expires_at: consultee_response_required_by.end_of_day,
        last_email_sent_at: nil,
        last_email_delivered_at: nil
      )

      SendConsulteeEmailJob.perform_later(self, consultee_email)
    end
  end

  def consultee_response_required_by(now = Time.zone.today)
    (now + consultee_response_period.days)
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
    parsed = JSON.parse(geojson)
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

  def apply_deadline_extension
    unless start_date?
      start_deadline
    end

    extend_deadline(deadline_extension.days.from_now)
  end

  def neighbour_exists?(new_neighbour)
    neighbours.find_by(address: new_neighbour[:address]).present?
  end
end
