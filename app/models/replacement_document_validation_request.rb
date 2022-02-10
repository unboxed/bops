# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ApplicationRecord
  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  private

  def audit_api_comment
    new_document.name
  end

  def audit_comment
    { old_document: old_document.name,
      reason: old_document.invalidated_document_reason }.to_json
  end
end
