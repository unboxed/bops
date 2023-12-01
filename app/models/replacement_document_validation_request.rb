# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ValidationRequest
  validates :cancel_reason, presence: true, if: :cancelled?
  validates :old_document, presence: true
  validates :reason, presence: true

  delegate :invalidated_document_reason, to: :old_document
  delegate :validated?, :archived?, to: :new_document, prefix: :new_document

  has_one :new_document, as: :owner, class_name: "Document"

  before_create :reset_replacement_document_validation_request_update_counter!
  before_create :set_document_owner
  before_destroy :reset_document_invalidation

  def replace_document!(file:, reason:)
    transaction do
      self.new_document = planning_application.documents.create!(
        file:,
        tags: old_document.tags,
        numbers: old_document.numbers,
        owner: self
      )

      close!
      old_document.update!(archive_reason: reason, archived_at: Time.zone.now)
    end
  end

  private

  def set_document_owner
    new_document&.update(owner: self)
  end

  def audit_comment
    {
      old_document: old_document.name,
      reason:
    }.to_json
  end

  def audit_api_comment
    new_document.name
  end

  def reset_document_invalidation
    transaction do
      Document.find(old_document_id)&.owner&.update_counter!
      old_document.update!(invalidated_document_reason: nil, validated: nil, owner: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentInvalidationError, e.message
  end

  def reset_replacement_document_validation_request_update_counter!
    # Find the validation request that the applicant responded to with the new document
    request = Document.find(old_document_id)&.owner

    request&.reset_update_counter!
  end
end
