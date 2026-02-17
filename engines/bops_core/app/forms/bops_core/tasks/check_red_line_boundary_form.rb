# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckRedLineBoundaryForm
      extend ActiveSupport::Concern

      include Rails.application.routes.url_helpers
      include Rails.application.routes.mounted_helpers

      included do
        self.task_actions = %w[save_and_complete mark_as_valid delete_request edit_form]

        class_attribute :reference_param_name, default: :planning_application_reference

        attribute :valid_red_line_boundary, :boolean
        attribute :validation_request_id, :integer

        with_options on: :save_and_complete do
          validates :valid_red_line_boundary, inclusion: {in: [true, false], message: "Select whether the red line boundary is correct"}
        end

        after_initialize do
          self.valid_red_line_boundary = planning_application.valid_red_line_boundary
        end
      end

      def redirect_url(options = {})
        return return_to if return_to.present?

        case action
        when "delete_request"
          super
        when "save_and_complete"
          if valid_red_line_boundary
            super
          else
            main_app.new_planning_application_validation_validation_request_path(
              planning_application,
              type: "red_line_boundary_change"
            )
          end
        else
          super
        end
      end

      def validation_request
        @validation_request ||= if validation_request_id.present?
          planning_application.red_line_boundary_change_validation_requests.find(validation_request_id)
        else
          planning_application.red_line_boundary_change_validation_requests.open_or_pending.first ||
            planning_application.red_line_boundary_change_validation_requests.closed.last
        end
      end

      def cancel_url
        route_for(
          :new_validation_request_cancellation,
          reference_param_name => planning_application.reference,
          :validation_request_id => validation_request.id,
          :task_slug => task.full_slug,
          :only_path => true
        )
      end

      def flash(type, controller)
        return nil unless type == :notice && after_success == "redirect"

        case action
        when "save_and_complete"
          controller.t(".check-red-line-boundary.success")
        when "mark_as_valid"
          controller.t(".check-red-line-boundary.mark_as_valid")
        when "delete_request"
          controller.t(".check-red-line-boundary.delete_request")
        end
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(valid_red_line_boundary:)
          valid_red_line_boundary ? task.complete! : task.in_progress!
        end
      end

      def mark_as_valid
        transaction do
          planning_application.update!(valid_red_line_boundary: true)
          task.complete!
        end
      end

      def delete_request
        transaction do
          validation_request.destroy!
          task.not_started!
        end
      end
    end
  end
end
