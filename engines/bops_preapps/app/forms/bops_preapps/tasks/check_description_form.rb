# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckDescriptionForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :valid_description, :boolean

      with_options on: :save_and_complete do
        validates :valid_description, inclusion: {in: [true, false], message: "Select whether the description is correct"}
      end

      after_initialize do
        self.valid_description = planning_application.valid_description
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
        if valid_description
          super
        else
          Rails.application.routes.url_helpers.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "description_change"
          )
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
