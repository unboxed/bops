class Recommendation < ApplicationRecord
  belongs_to :planning_application
  belongs_to :assessor, class_name: "User"
  belongs_to :reviewer, class_name: "User", optional: true

  attr_accessor :agree
end
