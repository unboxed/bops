# frozen_string_literal: true

module AssessmentTasksPresenter
  extend ActiveSupport::Concern

  def assessment_tasklist_in_progress?
    policy_classes.any? ||
      consistency_checklist.present? ||
      assessment_details.any? ||
      permitted_development_right.present? ||
      recommendation.present?
  end

  def multiple_policy_classes?
    policy_classes.count > 1
  end
end
