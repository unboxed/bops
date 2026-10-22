# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class SetTargetDateForm < Form
      include DateValidateable

      self.task_actions = %w[save_and_complete]

      attribute :target_date, :date
      validates :target_date, presence: true, date: {after: :current, message: "Enter a date after today’s date"}

      private

      def save_and_complete
        super do
          enforcement.update!(target_date:)
        end
      end
    end
  end
end
