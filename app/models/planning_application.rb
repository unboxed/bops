# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  enum application_type: { lawfulness_certificate: 0, full: 1 }

  enum status: { in_assessment: 0, awaiting_determination: 1, determined: 2 }

  has_one :policy_evaluation, dependent: :destroy
  has_many :decisions, dependent: :destroy

  has_many :drawings, dependent: :destroy

  has_one :assessor_decision, -> {
      joins(:user).where(users: { role: :assessor })
    }, class_name: "Decision", inverse_of: :planning_application

  has_one :reviewer_decision, -> {
      joins(:user).where(users: { role: :reviewer })
    }, class_name: "Decision", inverse_of: :planning_application

  belongs_to :site
  belongs_to :agent
  belongs_to :applicant
  belongs_to :user, optional: true

  before_create :set_target_date

  validate :assessor_decision_associated_with_assessor
  validate :reviewer_decision_associated_with_reviewer

  def days_left
    (target_date - Date.current).to_i
  end

  def update_and_timestamp_status(status)
    update(status: status, "#{status}_at": Time.current)
  end

  def reference
    @_reference ||= id.to_s.rjust(8, "0")
  end

  def correction_requested?
    awaiting_determination? && reviewer_decision.correction.present? &&
        reviewer_decision.updated_at > assessor_decision.updated_at if
        reviewer_decision.present?
  end

  def correction_provided?
    awaiting_determination? && reviewer_decision.correction.present? &&
        assessor_decision.updated_at > reviewer_decision.updated_at if
        reviewer_decision.present?
  end

  private

  def set_target_date
    self.target_date = created_at + 8.weeks
  end

  def assessor_decision_associated_with_assessor
    if assessor_decision.present? && !assessor_decision.user.assessor?
      errors.add(:assessor_decision, "cannot be associated with a non-assessor")
    end
  end

  def reviewer_decision_associated_with_reviewer
    if reviewer_decision.present? && !reviewer_decision.user.reviewer?
      errors.add(:reviewer_decision, "cannot be associated with a non-reviewer")
    end
  end
end
