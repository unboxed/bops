# frozen_string_literal: true

class AdditionalDocumentValidationRequest < ValidationRequest
  has_many :additional_documents, as: :owner, dependent: :destroy, class_name: "Document"

  validates :document_request_type, presence: true
  validates :reason, presence: true
  validates :cancel_reason, presence: true, if: :cancelled?

  after_create :set_documents_missing
  before_destroy :reset_documents_missing

  private

  def set_documents_missing
    return if planning_application.documents_missing?

    planning_application.update!(documents_missing: true)
  end
end
