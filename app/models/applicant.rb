# frozen_string_literal: true

class Applicant < ApplicationRecord
  has_many :planning_applications, dependent: :restrict_with_exception

  belongs_to :agent, optional: true
end
