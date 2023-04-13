# frozen_string_literal: true

module AssessmentTasksPresenter
  extend ActiveSupport::Concern

  def assessment_tasklist_in_progress?
    policy_classes.any? ||
      consistency_checklist.present? ||
      assessment_details.any? ||
      permitted_development_right.present? ||
      recommendation.present? ||
      immunity_validation_in_progress?
  end

  def multiple_policy_classes?
    policy_classes.count > 1
  end

  def immunity_validation_in_progress?
    planning_application.immunity_detail.present? && planning_application.immunity_detail.status != "not_started"
    ## Above line needs fixing when we add things that update the immunity details
  end
end
