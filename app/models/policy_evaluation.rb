# frozen_string_literal: true

class PolicyEvaluation < ApplicationRecord
  enum status: { pending: 0, met: 1, unmet: 2 }

  belongs_to :planning_application

  has_many :policy_considerations, dependent: :destroy

  validates :status, inclusion: { in: %w[met unmet] }, on: :update
end
