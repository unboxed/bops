# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class AddAndAssignConsulteesForm < Form
      self.task_actions = %w[save_draft save_and_complete]

      delegate :consultation, to: :planning_application

      def update(params)
        super do
          case action
          when "save_draft"
            task.update!(status: :in_progress)
          when "save_and_complete"
            task.complete!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def consultees
        @consultees ||= consultation&.consultees || Consultee.none
      end

      def constraints
        @constraints ||= planning_application.planning_application_constraints
      end
    end
  end
end
