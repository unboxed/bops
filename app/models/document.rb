# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :planning_application

  with_options optional: true do
    belongs_to :additional_document_validation_request
    belongs_to :user
    belongs_to :api_user
  end

  has_one_attached :file, dependent: :destroy

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
  validate :invalidated_comment_present?
  validate :created_date_is_in_the_past

  scope :active, -> { where(archived_at: nil) }
  scope :invalidated, -> { where(validated: false) }
  scope :referenced, -> { where(referenced_in_decision_notice: true) }
  scope :publishable, -> { where(publishable: true) }

  scope :for_publication, -> { active.publishable }
  scope :for_display, -> { active.referenced }

  scope :with_tag, ->(tag) { where("tags @> ?", "\"#{tag}\"") }

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

  def referenced_in_decision_notice?
    referenced_in_decision_notice == true
  end

  def archive(archive_reason)
    unless archived?
      update!(archive_reason: archive_reason,
              archived_at: Time.zone.now)
    end
  end

  def published?
    self.class.for_publication.where(id: id).any?
  end

  def received_at_or_created
    (received_at || created_at).to_date
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

  def invalidated_comment_present?
    if validated == false && invalidated_document_reason.blank?
      errors.add(:document_validation, "Please fill in the comment box with the reason(s) this document is not valid.")
    end
  end

  def created_date_is_in_the_past
    if received_at.present? && received_at > Time.zone.today
      errors.add(:received_at, "Date must be today or earlier. You cannot insert a future date.")
    end
  end
end
