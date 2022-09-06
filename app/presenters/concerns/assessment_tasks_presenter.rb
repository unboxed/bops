# frozen_string_literal: true

module AssessmentTasksPresenter
  extend ActiveSupport::Concern

  included do
    def assess_against_legislation_tasklist(policy_class)
      AssessmentTasks::AssessAgainstLegislationPresenter.new(
        @template, @planning_application, policy_class
      ).task_list_row
    end
  end
end
