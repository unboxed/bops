# frozen_string_literal: true

class AdditionalDocumentValidationRequest < ValidationRequest
  has_many :additional_documents, as: :owner, dependent: :destroy, class_name: "Document"

  validates :document_request_type, presence: true
  validates :reason, presence: true
  validates :cancel_reason, presence: true, if: :cancelled?

  after_create :set_documents_missing
  before_destroy :reset_documents_missing

  def can_upload?
    open? && may_close?
  end

  def can_cancel?
    may_cancel? && (planning_application.invalidated? || post_validation?)
  end

  def upload_files!(files)
    transaction do
      files.each do |file|
        planning_application.documents.create!(file:, owner: self)
      end
      close!
      audit_upload_files!
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise UploadFilesError, e.message
  end

  private

  def set_documents_missing
    return if planning_application.documents_missing?

    planning_application.update!(documents_missing: true)
  end

  def audit_comment
    {
      document: document_request_type,
      reason: reason
    }.to_json
  end

  def document
    @document ||= additional_documents.order(:created_at).last
  end

  def audit_upload_files!
    audit!(
      activity_type: "additional_document_validation_request_received",
      activity_information: sequence,
      audit_comment: additional_documents.map(&:name).join(", ")
    )
  end
end
