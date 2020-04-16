# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  enum application_type: { lawfulness_certificate: 0, full: 1 }

  enum status: { pending: 0, started: 1, completed: 2 }

  has_many :decisions, dependent: :destroy

  has_one :assessor_decision, -> {
      joins(:user).where(users: { role: :assessor })
    }, class_name: "Decision", inverse_of: :planning_application

  has_one :reviewer_decision, -> {
      joins(:user).where(users: { role: :reviewer })
    }, class_name: "Decision", inverse_of: :planning_application

  belongs_to :site
end
