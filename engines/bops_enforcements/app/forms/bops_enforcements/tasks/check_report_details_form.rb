# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckReportDetailsForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :urgent, :boolean

      private

      def save_and_complete
        super do
          enforcement.start_validation!
          enforcement.update!(urgent:)

          task.complete!
          task.parent.complete!
        end
      end
    end
  end
end
