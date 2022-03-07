# frozen_string_literal: true

module ValidationTasksPresenter
  extend ActiveSupport::Concern

  STATUSES = ["Not checked yet", "Invalid", "Valid"].freeze

  STATUS_COLOURS = {
    "Not checked yet": "grey",
    Invalid: "red",
    Valid: "green"
  }.freeze

  included do
    def document_task_list(document)
      ValidationTasks::DocumentsPresenter.new(@template, @planning_application, document).task_list_row
    end
  end
end
