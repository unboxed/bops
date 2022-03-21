# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ApplicationRecord
  class ResetDocumentInvalidationError < StandardError; end

  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  validates :reason, presence: true

  scope :with_active_document, -> { joins(:old_document).where(documents: { archived_at: nil }) }

  delegate :invalidated_document_reason, to: :old_document

  before_destroy :reset_document_invalidation

  def reset_document_invalidation
    old_document.update!(invalidated_document_reason: nil, validated: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentInvalidationError, e.message
  end

  private

  def audit_api_comment
    new_document.name
  end

  def audit_comment
    { old_document: old_document.name,
      reason: invalidated_document_reason }.to_json
  end
end
