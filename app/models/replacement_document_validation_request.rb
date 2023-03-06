# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ApplicationRecord
  class ResetDocumentInvalidationError < StandardError; end

  include ValidationRequestable

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  validates :reason, presence: true

  scope :with_active_document, -> { joins(:old_document).where(documents: { archived_at: nil }) }

  delegate :invalidated_document_reason, to: :old_document
  delegate :validated?, :archived?, to: :new_document, prefix: :new_document

  before_create :reset_replacement_document_validation_request_update_counter!
  before_destroy :reset_document_invalidation

  def reset_document_invalidation
    transaction do
      self.class.closed.find_by(new_document_id: old_document_id)&.update_counter!
      old_document.update!(invalidated_document_reason: nil, validated: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentInvalidationError, e.message
  end

  def replace_document!(file:, reason:)
    transaction do
      self.new_document = planning_application.documents.create!(
        file: file,
        tags: old_document.tags,
        numbers: old_document.numbers
      )

      close!
      old_document.update!(archive_reason: reason, archived_at: Time.zone.now)
    end
  end

  private

  def audit_api_comment
    new_document.name
  end

  def audit_comment
    { old_document: old_document.name,
      reason: invalidated_document_reason }.to_json
  end

  def reset_replacement_document_validation_request_update_counter!
    request = ReplacementDocumentValidationRequest.find_by(new_document_id: old_document_id)

    request&.reset_update_counter!
  end
end
