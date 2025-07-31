# frozen_string_literal: true

module TasksHelper
  def task_status_tag(task)
    colour = case task.status
    when "completed"
      "grey"
    else
      "blue"
    end

    classes = (task.status == "completed") ? "govuk-tag--status-review_complete" : ""

    govuk_tag(text: task.status.humanize, colour:, classes:)
  end
end
