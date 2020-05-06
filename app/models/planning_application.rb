# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  enum application_type: { lawfulness_certificate: 0, full: 1 }

  enum status: { in_assessment: 0, awaiting_determination: 1, determined: 2 }

  has_many :decisions, dependent: :destroy

  has_one :assessor_decision, -> {
      joins(:user).where(users: { role: :assessor })
    }, class_name: "Decision", inverse_of: :planning_application

  has_one :reviewer_decision, -> {
      joins(:user).where(users: { role: :reviewer })
    }, class_name: "Decision", inverse_of: :planning_application

  belongs_to :site
  belongs_to :agent
  belongs_to :applicant

  before_create :set_target_date

  def days_left
    (target_date - Date.current).to_i
  end

  private

  def set_target_date
    self.target_date = created_at + 8.weeks
  end
end
