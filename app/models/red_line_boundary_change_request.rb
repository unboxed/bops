class RedLineBoundaryChangeRequest < ApplicationRecord
  include ChangeRequest

  belongs_to :planning_application
  belongs_to :user
end
