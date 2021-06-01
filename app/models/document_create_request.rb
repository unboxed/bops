class DocumentCreateRequest < ApplicationRecord
  include ChangeRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :new_document, optional: true, class_name: "Document"

  validates :document_request_type, presence: { message: "Please fill in the document request type." }
  validates :document_request_reason, presence: { message: "Please fill in the reason for this document request." }
  scope :closed, -> { where(state: "closed") }
end
