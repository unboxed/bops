# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckRedLineBoundaryForm < BaseForm
      include ActiveModel::Attributes

      attribute :valid_red_line_boundary, :boolean

      validates :valid_red_line_boundary, inclusion: {in: [true, false], message: :blank}

      def update(params)
        assign_attributes(valid_red_line_boundary: params.dig(:planning_application, :valid_red_line_boundary))
        save
      end

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          planning_application.update!(valid_red_line_boundary:)
          task.complete! if valid_red_line_boundary
        end
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def redirect_url
        if valid_red_line_boundary == false
          Rails.application.routes.url_helpers.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "red_line_boundary_change"
          )
        else
          task_path(planning_application, task)
        end
      end

      def permitted_fields(params)
        params
      end
    end
  end
end
