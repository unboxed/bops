# frozen_string_literal: true

module Tasks
  class CheckLegislativeRequirementsForm < Form
    self.task_actions = %w[save_and_complete edit_form]

    def update(params)
      super do
        case action
        when "save_and_complete" then task.complete!

        when "edit_form" then task.in_progress!
        end
      end
    end
  end
end
