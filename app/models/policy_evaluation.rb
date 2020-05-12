# frozen_string_literal: true

class PolicyEvaluation < ApplicationRecord
  validates :requirements_met, inclusion: { in: [true, false] }

  belongs_to :planning_application
end
