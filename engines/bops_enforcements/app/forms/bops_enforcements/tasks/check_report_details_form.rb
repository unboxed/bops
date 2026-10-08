# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckReportDetailsForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :urgent, :boolean
      attribute :urgency_reason, :string

      validates :urgency_reason, presence: true, if: -> { urgent }

      private

      def save_and_complete
        super do
          enforcement.start_validation! if enforcement.not_started?
          enforcement.update!(urgent:, urgency_reason: urgent ? urgency_reason : nil)

          task.complete!
          task.parent.complete!
        end
      end
    end
  end
end
