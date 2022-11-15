# frozen_string_literal: true

module AssessmentTasksPresenter
  extend ActiveSupport::Concern

  included do
    def assess_against_legislation_tasklist(policy_class)
      AssessmentTasks::AssessAgainstLegislationPresenter.new(
        @template, @planning_application, policy_class
      ).task_list_row
    end

    def assessment_detail_tasklist(category)
      AssessmentTasks::AssessmentDetailPresenter.new(
        @template, @planning_application, category
      ).task_list_row
    end

    def review_documents_tasklist
      AssessmentTasks::ReviewDocumentsPresenter.new(
        @template, @planning_application
      ).task_list_row
    end

    def permitted_development_right_tasklist
      AssessmentTasks::PermittedDevelopmentRightPresenter.new(
        @template, @planning_application
      ).task_list_row
    end
  end

  def assessment_tasklist_in_progress?
    policy_classes.any? ||
      consistency_checklist.present? ||
      assessment_details.any? ||
      permitted_development_right.present?
  end

  def multiple_policy_classes?
    policy_classes.count > 1
  end
end
