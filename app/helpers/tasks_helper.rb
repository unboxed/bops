# frozen_string_literal: true

module TasksHelper
  def task_status_tag(task)
    colour = case task.status
    when "completed"
      "green"
    else
      "blue"
    end

    govuk_tag(text: task.status.humanize, colour:)
  end
end
