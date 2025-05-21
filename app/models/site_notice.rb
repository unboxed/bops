# frozen_string_literal: true

class SiteNotice < ApplicationRecord
  class NotCreatableError < StandardError; end

  SAFE_TAGS = %w[div h1 h2 h3 p ul li table tr td th hr].freeze
  SAFE_ATTRIBUTES = %w[style].freeze

  include DateValidateable
  include Consultable

  belongs_to :planning_application
  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  validates :required, inclusion: {in: [true, false]}

  with_options on: :confirmation do
    validates :displayed_at,
      presence: true,
      date: {
        on_or_before: :current
      }

    validate :document_presence
  end

  with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
    validates :internal_team_email, allow_blank: true
  end

  before_create :ensure_publicity_feature!

  after_update :extend_consultation!, if: :saved_change_to_displayed_at?

  attr_reader :method

  alias_method :consultable_event_at, :displayed_at

  class << self
    def latest!
      by_created_at_desc.first!
    end
  end

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file: file, planning_application: planning_application, tags: %w[internal.siteNotice])
    end
  end

  def document
    documents.select(&:persisted?).min_by(&:created_at)
  end

  def preview_content
    start_deadline unless consultation_started?

    site_notice_type = consultation.planning_application.environment_impact_assessment&.required? ? "eia" : "default"

    I18n.t("site_notice_template.#{site_notice_type}",
      council: planning_application.local_authority.subdomain.capitalize,
      reference: planning_application.reference,
      application_description: planning_application.description,
      site_address: planning_application.full_address,
      applicant_name: "#{planning_application.applicant_first_name} #{planning_application.applicant_last_name}",
      application_link:,
      council_address: I18n.t("council_addresses.#{planning_application.local_authority.subdomain}"),
      consultation_end_date: consultation_end_date.to_date.to_fs,
      site_notice_display_date: displayed_at&.to_date&.to_fs || Time.zone.today.to_fs,
      legislation_title: planning_application.application_type.legislation_title,
      eia_statement: eia_statement)
  end

  def sanitized_content
    sanitizer.sanitize(content, tags: SAFE_TAGS, attributes: SAFE_ATTRIBUTES)&.html_safe
  end

  def incomplete?
    required? && !displayed_at?
  end

  def complete?
    !incomplete?
  end

  def last_document
    @last_document ||= documents.preload(:user).order(created_at: :desc).first
  end

  def uploaded_by
    last_document&.user
  end

  private

  def sanitizer
    @sanitize ||= Rails::HTML5::Sanitizer.safe_list_sanitizer.new
  end

  def application_link
    "#{planning_application.local_authority.applicants_url}/planning_applications/#{planning_application.reference}"
  end

  def eia_statement
    eia = planning_application.environment_impact_assessment
    if eia&.required? && eia&.with_address_email_and_fee?
      "<p>You can request a hard copy for a fee of £#{eia.fee} by emailing #{eia.email_address} or in person at #{eia.address}.</p>"
    end
  end

  def ensure_publicity_feature!
    return if planning_application.publicity_consultation_feature?

    raise NotCreatableError,
      "Cannot create site notice when application type does not permit this feature."
  end

  def document_presence
    errors.add(:documents, "Upload a photo or document of the site notice to continue") if documents.empty?
  end
end
