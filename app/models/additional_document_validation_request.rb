# frozen_string_literal: true

class AdditionalDocumentValidationRequest < ApplicationRecord
  class ResetDocumentsMissingError < StandardError; end

  class UploadFilesError < RuntimeError; end

  include ValidationRequestable

  belongs_to :planning_application
  belongs_to :user

  has_many :documents, dependent: :destroy

  validates :document_request_type, presence: { message: "Please fill in the document request type." }
  validates :document_request_reason, presence: { message: "Please fill in the reason for this document request." }

  after_create :set_documents_missing
  before_destroy :reset_documents_missing

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

  def set_documents_missing
    return if planning_application.documents_missing?

    planning_application.update!(documents_missing: true)
  end

  def reset_documents_missing
    return if planning_application.additional_document_validation_requests.open_or_pending.excluding(self).any?

    planning_application.update!(documents_missing: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentsMissingError, e.message
  end

  def can_cancel?
    may_cancel? && (planning_application.invalidated? || post_validation?)
  end

  def document
    @document ||= documents.order(:created_at).last
  end

  private

  def audit_upload_files!
    audit!(
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
