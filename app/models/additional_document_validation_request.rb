# frozen_string_literal: true

class AdditionalDocumentValidationRequest < ApplicationRecord
  class UploadFilesError < RuntimeError; end
  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user

  has_many :documents, dependent: :destroy

  validates :document_request_type, presence: { message: "Please fill in the document request type." }
  validates :document_request_reason, presence: { message: "Please fill in the reason for this document request." }

  def upload_files!(files)
    transaction do
      files.each do |file|
        planning_application.documents.create!(file: file, additional_document_validation_request: self)
      end
      close!
      audit_upload_files!
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise UploadFilesError, e.message
  end

  def can_upload?
    open? && may_close?
  end

  private

  def audit_upload_files!
    audit_created!(
      activity_type: "additional_document_validation_request_received",
      activity_information: sequence,
      audit_comment: documents.map(&:name).join(", ")
    )
  end

  def audit_comment
    { document: document_request_type,
      reason: document_request_reason }.to_json
  end
end
