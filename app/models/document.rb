# frozen_string_literal: true

class Document < ApplicationRecord
  class NotArchiveableError < StandardError; end

  belongs_to :planning_application

  delegate :audits, to: :planning_application
  delegate :representable?, to: :file

  include Auditable

  with_options optional: true do
    belongs_to :additional_document_validation_request
    belongs_to :user
    belongs_to :api_user
  end

  has_one :replacement_document_validation_request,
          lambda { |document|
            unscope(:where).where(old_document_id: document.id, cancelled_at: nil)
          },
          dependent: :destroy,
          inverse_of: false

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
    "Other"
  ].freeze

  TAGS = PLAN_TAGS + EVIDENCE_TAGS

  PERMITTED_CONTENT_TYPES = ["application/pdf", "image/png", "image/jpeg"].freeze

  validate :tag_values_permitted
  validate :file_content_type_permitted
  validate :file_attached
  validate :numbered
  validate :created_date_is_in_the_past

  scope :by_created_at, -> { order(created_at: :asc) }
  scope :active, -> { where(archived_at: nil) }
  scope :invalidated, -> { where(validated: false) }
  scope :referenced, -> { where(referenced_in_decision_notice: true) }
  scope :publishable, -> { where(publishable: true) }

  scope :for_publication, -> { active.publishable }
  scope :for_display, -> { active.referenced }

  scope :with_tag, ->(tag) { where("tags @> ?", "\"#{tag}\"") }
  scope :with_file_attachment, -> { includes(file_attachment: :blob) }

  scope(
    :referenced_in_decision_notice,
    -> { where(referenced_in_decision_notice: true) }
  )

  before_create do
    self.api_user ||= Current.api_user
    self.user ||= Current.user
  end

  def name
    file.filename if file.attached?
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
      raise NotArchiveableError, "Cannot archive document with an open or pending validation request"
    end

    return if archived?

    transaction do
      update!(archive_reason: archive_reason, archived_at: Time.zone.now)
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
    self.class.for_publication.where(id: id).any?
  end

  def received_at_or_created
    (received_at || created_at).to_date
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
    file.representation(resize_to_limit: resize_to_limit).processed.url
  rescue ActiveStorage::PreviewError => e
    logger.warn("Image retrieval failed for document ##{id} with error '#{e.message}'")
    nil
  end

  private

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
    { previous_received_date: saved_change_to_received_at.first,
      updated_received_date: saved_change_to_received_at.second }.to_json
  end

  def reset_replacement_document_validation_request_update_counter!
    return unless validated? || archived?

    return unless (request = ReplacementDocumentValidationRequest.find_by(new_document_id: id))

    request.reset_update_counter!
  end
end
