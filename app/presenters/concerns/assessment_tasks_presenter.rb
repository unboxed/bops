# frozen_string_literal: true

module AssessmentTasksPresenter
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/AbcSize
  def assessment_tasklist_in_progress?
    policy_classes.any? ||
      consistency_checklist.present? ||
      assessment_details.any? ||
      permitted_development_right.present? ||
      recommendation.present? ||
      (planning_application.immunity_detail.present? && planning_application.immunity_detail.status != "not_started")
    ## Above line needs fixing when we add things that update the immunity details
  end
  # rubocop:enable Metrics/AbcSize

  def multiple_policy_classes?
    policy_classes.count > 1
  end
end
