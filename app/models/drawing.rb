# frozen_string_literal: true

class Drawing < ApplicationRecord
  belongs_to :planning_application

  has_one_attached :plan
end
