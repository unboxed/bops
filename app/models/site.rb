# frozen_string_literal: true

class Site < ApplicationRecord
  has_many :planning_applications, dependent: :restrict_with_exception
end
