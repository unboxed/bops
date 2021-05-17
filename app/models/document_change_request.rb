class DocumentChangeRequest < ApplicationRecord
  include ChangeRequest

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  scope :open, -> { where(state: "open") }
end
