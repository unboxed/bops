# frozen_string_literal: true

module Api
  module V1
    class RedLineBoundaryChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application

      def index
        respond_to do |format|
          format.json do
            @red_line_boundary_change_validation_requests =
              @planning_application.red_line_boundary_change_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          if (@red_line_boundary_change_validation_request =
                @planning_application.red_line_boundary_change_validation_requests.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: {
                       message: "Unable to find red line boundary change validation request with id: #{params[:id]}"
                     },
                status: :not_found
            end
          end
        end
      end

      def update
        @red_line_boundary_change_validation_request =
          @planning_application.red_line_boundary_change_validation_requests.find(params[:id])

        if @red_line_boundary_change_validation_request.update(red_line_boundary_change_params)
          @red_line_boundary_change_validation_request.close!
          if @red_line_boundary_change_validation_request.applicant_approved?
            @planning_application.update!(boundary_geojson: @red_line_boundary_change_validation_request.new_geojson)
          end

          @red_line_boundary_change_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor
          render json: {message: "Validation request updated"}, status: :ok
        else
          render json: {
                   message: "Unable to update request. Please ensure rejection_reason is present if approved is false."
                 },
            status: :bad_request
        end
      end

      private

      def red_line_boundary_change_params
        {applicant_approved: params[:data][:applicant_approved],
         applicant_rejection_reason: params[:data][:applicant_rejection_reason]}
      end
    end
  end
end
