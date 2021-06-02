class RedLineBoundaryChangeRequest < ApplicationRecord
  include ChangeRequest

  belongs_to :planning_application
  belongs_to :user

  validates :new_geojson, presence: { message: "Red line drawing must be complete" }
  validates :reason, presence: { message: "Provide a reason for changes" }
end
