# frozen_string_literal: true

class Document < ApplicationRecord
  class NotArchiveableError < StandardError; end

  belongs_to :planning_application

  with_options optional: true do
    belongs_to :user
    belongs_to :api_user
    belongs_to :owner, polymorphic: true
    belongs_to :evidence_group
    belongs_to :site_visit
    belongs_to :site_notice
    belongs_to :neighbour_response
  end

  has_one :replacement_document_validation_request,
    lambda { |document|
      unscope(:where).where(old_document_id: document.id, cancelled_at: nil)
    },
    dependent: :destroy,
    inverse_of: false

  delegate :audits, to: :planning_application
  delegate :representable?, to: :file

  include Auditable

  has_one_attached :file, dependent: :destroy
  after_create :create_audit!
  before_update :reset_replacement_document_validation_request_update_counter!
  after_update :audit_updated!

  PLAN_TAGS = %w[
    Front
    Rear
    Side
    Roof
    Floor
    Site
    Plan
    Elevation
    Section
    Proposed
    Existing
  ].freeze

  EVIDENCE_TAGS = [
    "Photograph",
    "Utility Bill",
    "Building Control Certificate",
    "Construction Invoice",
    "Council Tax Document",
    "Tenancy Agreement",
    "Tenancy Invoice",
    "Bank Statement",
    "Statutory Declaration",
    "Discounts",
    "Other"
  ].freeze

  SUPPORTING_DOCUMENT_TAGS = [
    "Site Visit",
    "Site Notice",
    "Press Notice",
    "Design and Access Statement",
    "Planning Statement",
    "Viability Appraisal",
    "Heritage Statement",
    "Agricultural, Forestry or Occupational Worker Dwelling Justification",
    "Arboricultural Assessment",
    "Structural Survey/report",
    "Air Quality Assessment",
    "Basement Impact Assessment",
    "Biodiversity Net Gain (from April)",
    "Contaminated Land Assessment",
    "Daylight and Sunlight Assessment",
    "Flood Risk Assessment/Drainage and SuDs Report",
    "Landscape and Visual Impact Assessment",
    "Noise Impact Assessment",
    "Open Space Assessment",
    "Sustainability and Energy Statement",
    "Transport Statement",
    "NDSS Compliance Statement",
    "Ventilation/Extraction Statement",
    "Community Infrastructure Levy (CIL) form",
    "Gypsy and Traveller Statement",
    "HMO statement",
    "Specialist Accommodation Statement",
    "Student Accommodation Statement",
    "Fee Exemption",
    "Other Supporting Document"
  ].freeze

  ## Needs to be better
  EVIDENCE_QUESTIONS = {
    utility_bill: [
      "What do these utility bills show?",
      "What date do these utility bills start from?",
      "What date do these utility bills run until?"
    ],
    photograph: ["What do these photographs show?"],
    building_control_certificate: [
      "When was this building control certificate issued?",
      "What do these building control certificates show?"
    ],
    construction_invoice: ["What do these construction invoices show?"],
    council_tax_document: [
      "What date do these council tax bills start from?",
      "When do these councils tax bills run until?",
      "What do these Council Tax documents show?"
    ],
    tenancy_agreement: [
      "What date do these tenancy agreements start from?",
      "When do these tenancy agreements run until?",
      "What do these tenancy agreements show?"
    ],
    tenancy_invoice: [
      "What date do these tenancy invoices start from?",
      "When do these tenancy invoices run until?",
      "What do these tenancy invoices show?"
    ],
    bank_statement: [
      "What date do these bank statements start from?",
      "When do these bank statements run until?",
      "What do these bank statements show?"
    ],
    other: ["What do these documents show?"]
  }.freeze

  DEFAULT_TABS = ["All", "Plans", "Supporting documents", "Evidence"].freeze
  TAGS_MAP = {
    "Plans" => PLAN_TAGS,
    "Supporting documents" => SUPPORTING_DOCUMENT_TAGS,
    "Evidence" => EVIDENCE_TAGS
  }.freeze

  TAGS = PLAN_TAGS + EVIDENCE_TAGS + SUPPORTING_DOCUMENT_TAGS

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"].freeze
  EXCLUDED_OWNERS = %w[PressNotice SiteNotice SiteVisit].freeze

  attr_accessor :replacement_file

  validate :no_open_replacement_request, if: :replacement_file
  validate :tag_values_permitted
  validate :file_content_type_permitted
  validate :file_attached
  validate :numbered
  validate :created_date_is_in_the_past

  default_scope -> { no_owner.or(not_excluded_owners) }

  scope :no_owner, -> { where(owner_type: nil) }
  scope :not_excluded_owners, -> { where.not(owner_type: EXCLUDED_OWNERS) }
  scope :by_created_at, -> { order(created_at: :asc) }
  scope :active, -> { where(archived_at: nil) }
  scope :invalidated, -> { where(validated: false) }
  scope :redacted, -> { where(redacted: true) }
  scope :not_redacted, -> { where.not(redacted: true) }
  scope(
    :referenced_in_decision_notice,
    -> { where(referenced_in_decision_notice: true) }
  )
  scope :publishable, -> { where(publishable: true) }

  scope :for_publication, -> { active.publishable }
  scope :for_display, -> { active.referenced_in_decision_notice }

  scope :with_tag, ->(tag) { where("tags @> ?", "\"#{tag}\"") }
  scope :with_file_attachment, -> { includes(file_attachment: :blob) }
  scope :for_site_visit, -> { where.not(site_visit_id: nil) }
  scope :for_fee_exemption, -> { with_tag("Fee Exemption") }
  scope :not_for_fee_exemption, -> { where("NOT (tags @> ?)", "\"Fee Exemption\"") }

  before_validation on: :create do
    if owner.present?
      self.planning_application ||= owner.planning_application
    end
  end

  before_create do
    self.api_user ||= Current.api_user
    self.user ||= Current.user
  end

  def name
    file.filename.to_s if file.attached?
  end

  def archived?
    archived_at.present?
  end

  def unarchived?
    !archived?
  end

  def referenced_in_decision_notice?
    referenced_in_decision_notice == true
  end

  def archive(archive_reason)
    if replacement_document_validation_request.try(:open_or_pending?)
      raise NotArchiveableError,
        "Cannot archive document with an open or pending validation request"
    end

    return if archived?

    transaction do
      update!(archive_reason:, archived_at: Time.zone.now)
      audit!(activity_type: "archived", activity_information: file.filename, audit_comment: archive_reason)
    end
  end

  def unarchive!
    transaction do
      update!(archived_at: nil)
      audit!(activity_type: "unarchived", activity_information: file.filename)
    end
  end

  def published?
    self.class.for_publication.where(id:).any?
  end

  def received_at_or_created
    (received_at || created_at).to_date.to_fs
  end

  def audit_updated!
    return unless saved_changes?

    if saved_change_to_attribute?("received_at")
      audit!(activity_type: "document_received_at_changed", activity_information: file.filename,
        audit_comment: audit_date_comment)
    end
    if saved_change_to_attribute?(:validated, from: false, to: true)
      audit!(activity_type: "document_changed_to_validated", activity_information: file.filename)
    elsif saved_change_to_attribute?(:validated, to: false)
      audit!(activity_type: "document_invalidated", activity_information: file.filename,
        audit_comment: invalidated_document_reason)
    end
  end

  def invalidated_document_reason
    replacement_document_validation_request.try(:reason) || super
  end

  def image_url(resize_to_limit = [1000, 1000])
    file.representation(resize_to_limit:).processed.url
  rescue ActiveStorage::PreviewError => e
    logger.warn("Image retrieval failed for document ##{id} with error '#{e.message}'")
    nil
  end

  def update_or_replace(attributes)
    self.attributes = attributes
    self.replacement_file = attributes[:file]
    return false unless valid?

    if replacement_file.present?
      planning_application.documents.create(attributes)
      reload.archive(I18n.t("document.replacement_document_uploaded"))
    else
      save
    end
  end

  def blob_url
    file.representation(resize_to_limit: [1000, 1000]) if file.representable?
  end

  private

  def no_open_replacement_request
    return unless replacement_document_validation_request&.open_or_pending?

    errors.add(:file, :open_replacement_request)
  end

  def tag_values_permitted
    errors.add(:tags, :unpermitted_tags) unless (tags - Document::TAGS).empty?
  end

  def file_content_type_permitted
    return unless file.attached? && file.blob&.content_type

    errors.add(:file, :unsupported_file_type) unless PERMITTED_CONTENT_TYPES.include? file.blob.content_type
  end

  def file_attached
    errors.add(:file, :missing_file) unless file.attached?
  end

  def numbered
    errors.add(:numbers, :missing_numbers) if referenced_in_decision_notice? && numbers.blank?
  end

  def created_date_is_in_the_past
    return unless received_at.present? && received_at > Time.zone.today

    errors.add(:received_at, "Date must be today or earlier. You cannot insert a future date.")
  end

  def create_audit!
    audit!(activity_type: "uploaded", activity_information: file.filename)
  end

  def audit_date_comment
    {previous_received_date: saved_change_to_received_at.first,
     updated_received_date: saved_change_to_received_at.second}.to_json
  end

  def reset_replacement_document_validation_request_update_counter!
    return unless validated? || archived?
    return if owner.nil?

    owner.reset_update_counter!
  end
end
