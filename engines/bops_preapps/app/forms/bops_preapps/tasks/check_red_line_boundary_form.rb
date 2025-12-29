# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckRedLineBoundaryForm < Form
      self.task_actions = %w[save_and_complete mark_as_valid]

      attribute :valid_red_line_boundary, :boolean

      with_options on: :save_and_complete do
        validates :valid_red_line_boundary, inclusion: {in: [true, false], message: "Select whether the red line boundary is correct"}
      end

      after_initialize do
        self.valid_red_line_boundary = planning_application.valid_red_line_boundary
      end

      def update(params)
        super do
          case action
          when "save_and_complete"
            save_and_complete
          when "mark_as_valid"
            mark_as_valid
          end
        end
      end

      def redirect_url(options = {})
        return return_to if return_to.present?

        if valid_red_line_boundary
          super
        else
          Rails.application.routes.url_helpers.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "red_line_boundary_change"
          )
        end
      end

      def validation_request
        @validation_request ||= planning_application.red_line_boundary_change_validation_requests.open_or_pending.first ||
          planning_application.red_line_boundary_change_validation_requests.closed.last
      end

      def flash(type, controller)
        return nil unless type == :notice && after_success == "redirect"

        case action
        when "save_and_complete"
          controller.t(".check-red-line-boundary.success")
        when "mark_as_valid"
          controller.t(".check-red-line-boundary.mark_as_valid")
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
    end
  end
end
