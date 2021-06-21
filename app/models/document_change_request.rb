class DocumentChangeRequest < ApplicationRecord
  include ChangeRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  before_create :set_sequence

  scope :open, -> { where(state: "open") }

  def set_sequence
    change_requests = PlanningApplication.find(planning_application.id).document_change_requests
    increment_sequence(change_requests)
  end
end
