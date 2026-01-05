# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckConstraintsForm < Form
      self.task_actions = %w[add_constraint remove_constraint save_draft save_and_complete edit_form]

      attribute :constraint_id, :integer

      delegate :planning_application_constraints, to: :planning_application

      def update(params)
        super do
          case action
          when "add_constraint"
            add_constraint
          when "remove_constraint"
            remove_constraint
          when "save_draft"
            save_draft
          when "save_and_complete"
            save_and_complete
          when "edit_form"
            task.in_progress!
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def other_constraints(search_param:)
        Constraint.other_constraints(search_param, planning_application)
      end

      def form_params(params)
        params.fetch(param_key, {}).permit(:constraint_id)
      end

      def flash(type, controller)
        case action
        when "add_constraint", "remove_constraint", "save_draft"
          case type
          when :notice
            controller.t(".#{slug}.#{action}.success")
          when :alert
            controller.t(".#{slug}.#{action}.failure")
          end
        else
          super
        end
      end

      private

      def add_constraint
        transaction do
          create_constraint! && task.start!
        end
      end

      def create_constraint!
        planning_application_constraints.create!(constraint_id:, identified_by: Current.user.name)
      end

      def remove_constraint
        transaction do
          constraint = planning_application_constraints.find(constraint_id)
          constraint.destroy! && task.start!
        end
      end
    end
  end
end
