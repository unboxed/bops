# frozen_string_literal: true

module ValidationTasksPresenter
  extend ActiveSupport::Concern

  STATUSES = ["Not checked yet", "Invalid", "Valid", "Updated"].freeze

  STATUS_COLOURS = {
    "Not checked yet": "grey",
    Invalid: "red",
    Valid: "green",
    Updated: "yellow"
  }.freeze

  included do
    def document_task_list(document)
      ValidationTasks::DocumentsPresenter.new(@template, @planning_application, document).task_list_row
    end

    def fee_task_list
      ValidationTasks::FeeItemsPresenter.new(@template, @planning_application).task_list_row
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
