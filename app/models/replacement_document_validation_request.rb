# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ApplicationRecord
  include AuditableModel

  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  delegate :audits, to: :planning_application

  def create_api_audit!
    audit_created!(
      activity_type: "replacement_document_validation_request_received",
      activity_information: sequence.to_s,
      audit_comment: audit_api_comment
    )
  end

  private

  def audit_api_comment
    new_document.name
  end
end
