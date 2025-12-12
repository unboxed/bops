# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckFeeForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :valid_fee, :boolean

      with_options on: :save_and_complete do
        validates :valid_fee, inclusion: {in: [true, false], message: "Select whether the fee is correct"}
      end

      after_initialize do
        self.valid_fee = planning_application.valid_fee
      end

      def update(params)
        super do
          case action
          when "save_and_complete"
            save_and_complete
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def redirect_url(options = {})
        if valid_fee
          super
        else
          Rails.application.routes.url_helpers.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "fee_change"
          )
        end
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(valid_fee:)
          valid_fee ? task.complete! : task.in_progress!
        end
      end
    end
  end
end
