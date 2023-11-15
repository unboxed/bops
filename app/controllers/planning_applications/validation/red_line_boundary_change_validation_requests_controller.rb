# frozen_string_literal: true

module PlanningApplications
  module Validation
    class RedLineBoundaryChangeValidationRequestsController < ValidationRequestsController
      include ValidationRequests

      before_action :ensure_no_open_or_pending_red_line_boundary_validation_request, only: %i[new]
      before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]

      def show
        @red_line_boundary_change_validation_request =
          @planning_application.red_line_boundary_change_validation_requests.find(params[:id])
      end

      def new
        @red_line_boundary_change_validation_request =
          @planning_application.red_line_boundary_change_validation_requests.new
      end

      def create
        @red_line_boundary_change_validation_request =
          RedLineBoundaryChangeValidationRequest.new(
            red_line_boundary_change_validation_request_params.merge!({planning_application_id: @planning_application.id})
          )
        @red_line_boundary_change_validation_request.user = current_user

        if @red_line_boundary_change_validation_request.save
          redirect_to(
            create_request_redirect_url,
            notice: t(".validation_request_for")
          )
        else
          render :new
        end
      end

      def create_request_redirect_url
        case return_to
        when nil
          super
        when planning_application_validation_sitemap_url(@planning_application)
          planning_application_validation_tasks_path(@planning_application)
        else
          return_to
        end
      end

      def return_to
        params.dig(:red_line_boundary_change_validation_request, :return_to)
      end

      private

      def red_line_boundary_change_validation_request_params
        params.require(:red_line_boundary_change_validation_request).permit(:new_geojson, :reason)
      end
    end
  end
end
