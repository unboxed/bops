# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckConstraintsForm < Form
      self.task_actions = %w[save_draft save_and_complete]
      after_initialize do
      end

      delegate :planning_application_constraints, to: :planning_application

      def update(params)
        super do
          case action
          when "save_draft"
            task.start!
          when "save_and_complete"
            task.complete!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def other_constraints(search_param:)
        Constraint.other_constraints(search_param, planning_application)
      end

      def form_params(params)
        {}
      end
    end
  end
end
