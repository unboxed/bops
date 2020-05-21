# frozen_string_literal: true

class PolicyEvaluation < ApplicationRecord
  belongs_to :planning_application

  enum status: { pending: 0, met: 1, unmet: 2 }
end
