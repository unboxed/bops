# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckRedLineBoundaryForm < BaseForm
      include ActiveModel::Attributes
      include Rails.application.routes.url_helpers

      attribute :valid_red_line_boundary, :boolean

      validates :valid_red_line_boundary, inclusion: { in: [true, false], message: :blank }

      delegate :errors, to: :planning_application, prefix: true

      def update(params)
        assign_attributes(boundary_validation_attributes(params))
        save
      end

      def save
        return false unless valid?

        if planning_application.update(valid_red_line_boundary:)
          task.complete! if valid_red_line_boundary
          true
        else
          false
        end
      end

      def permitted_fields(params)
        params
      end

      def redirect_url
        if valid_red_line_boundary == false
          new_planning_application_validation_validation_request_path(
            planning_application,
            type: "red_line_boundary_change"
          )
        else
          BopsPreapps::Engine.routes.url_helpers.task_path(
            reference: planning_application.reference,
            slug: task.full_slug
          )
        end
      end

      private

      def boundary_validation_attributes(params)
        return {} unless params[:planning_application]

        permitted = params.require(:planning_application).permit(:valid_red_line_boundary)

        if permitted[:valid_red_line_boundary].present?
          permitted[:valid_red_line_boundary] = permitted[:valid_red_line_boundary] == "true"
        end
        permitted
      end
    end
  end
end
