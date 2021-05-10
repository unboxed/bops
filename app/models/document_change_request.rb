class DocumentChangeRequest < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user
  belongs_to :document
end
