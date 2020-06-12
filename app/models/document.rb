class Document < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :plan
end
