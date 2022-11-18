# frozen_string_literal: true

module ReviewTasksPresenter
  extend ActiveSupport::Concern

  included do
    def permitted_development_right_review_tasklist
      ReviewTasks::PermittedDevelopmentRightPresenter.new(
        @template, @planning_application
      ).task_list_row
    end
  end
end
