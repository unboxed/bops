# frozen_string_literal: true

module PlanningApplications
  module Validation
    class SitemapsController < BaseController
      def show
        respond_to do |format|
          format.html
        end
      end

      def validate
        @planning_application.update!(red_line_boundary_params)

        respond_to do |format|
          format.html do
            if @planning_application.valid_red_line_boundary?
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            elsif @planning_application.valid_red_line_boundary.nil?
              flash.now[:alert] = t(".failure")
              render :show
            else
              redirect_to new_planning_application_validation_validation_request_path(type: "red_line_boundary_change")
            end
          end
        end
      end

      def update
        audit_action = @planning_application.boundary_geojson.blank? ? "created" : "updated"

        respond_to do |format|
          if @planning_application.update(boundary_geojson: boundary_geojson_params[:boundary_geojson],
            boundary_created_by: current_user)

            @planning_application.audit_boundary_geojson!(audit_action)

            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            end
          else
            flash.now[:alert] = t(".failure")
            flash.now[:alert] << (": #{@planning_application.errors.join("; ")}") if @planning_application.errors.present?
            render :show
          end
        end
      end

      private

      def boundary_geojson_params
        params.require(:planning_application).permit(:boundary_geojson)
      end

      def red_line_boundary_params
        if params[:planning_application]
          params.require(:planning_application).permit(:valid_red_line_boundary)
        else
          params.permit(:valid_red_line_boundary)
        end
      end
    end
  end
end
