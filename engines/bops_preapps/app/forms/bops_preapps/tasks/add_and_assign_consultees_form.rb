# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class AddAndAssignConsulteesForm < Form
      self.task_actions = %w[save_draft save_and_complete]

      delegate :consultation, to: :planning_application

      def consultees
        @consultees ||= consultation&.consultees || Consultee.none
      end

      def constraints
        @constraints ||= planning_application.planning_application_constraints
      end
    end
  end
end
