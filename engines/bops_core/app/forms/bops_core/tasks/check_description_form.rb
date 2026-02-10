# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckDescriptionForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete edit_form]

        attribute :valid_description, :boolean

        with_options on: :save_and_complete do
          validates :valid_description, inclusion: {in: [true, false], message: "Select whether the description is correct"}
        end

        after_initialize do
          self.valid_description = planning_application.valid_description
        end
      end

      def update(params)
        super do
          if task_actions.include?(action)
            send(action.to_sym)
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      def validation_request
        @validation_request ||= planning_application.description_change_validation_requests.open_or_pending.first ||
          planning_application.description_change_validation_requests.closed.last
      end

      def description_validation_request?
        validation_request.present?
      end

      def description_was_updated?
        @description_was_updated ||= planning_application.description_change_validation_requests.closed.approved.exists?
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(valid_description:)
          valid_description ? task.complete! : task.in_progress!
        end
      end
    end
  end
end
