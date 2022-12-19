# frozen_string_literal: true

module ValidationTasksPresenter
  extend ActiveSupport::Concern

  STATUSES = ["Not checked yet", "Not started", "Invalid", "Valid", "Updated"].freeze

  STATUS_COLOURS = {
    "Not checked yet": "grey",
    "Not started": "grey",
    Invalid: "red",
    Valid: "green",
    Updated: "yellow"
  }.freeze

  included do
    def items_counter
      ValidationTasks::ItemsCounterPresenter.new(@template, @planning_application).items_count
    end

    def red_line_boundary_task_list
      ValidationTasks::RedLineBoundaryPresenter.new(@template, @planning_application).task_list_row
    end

    def other_change_task_list(other_change_validation_request)
      ValidationTasks::OtherChangePresenter.new(@template, @planning_application,
                                                other_change_validation_request).task_list_row
    end

    def review_task_list
      ValidationTasks::ReviewPresenter.new(@template, @planning_application).task_list_row
    end

    private

    def validation_item_tag
      classes = ["govuk-tag govuk-tag--#{validation_item_status_tag_colour} app-task-list__task-tag"]

      tag.strong class: classes do
        validation_item_status
      end
    end

    def validation_item_status_tag_colour
      STATUS_COLOURS[validation_item_status.to_sym]
    end
  end
end
