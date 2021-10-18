# frozen_string_literal: true

module Api
  module V1
    class DescriptionChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token, only: :update
      before_action :check_token_and_set_application, only: :update

      def update
        @description_change_validation_request = @planning_application.description_change_validation_requests.where(id: params[:id]).first

        if @description_change_validation_request.update(description_change_params)
          @description_change_validation_request.update!(state: "closed")
          if @description_change_validation_request.approved?
            @planning_application.update!(description: @description_change_validation_request.proposed_description)
          end

          audit("description_change_validation_request_received", description_audit_item(@description_change_validation_request),
                @description_change_validation_request.sequence, current_api_user)

          render json: { message: "Description change request updated" }, status: :ok
        else
          render json: { message: "Unable to update request. Please ensure rejection_reason is present if approved is false." },
                 status: :bad_request
        end
      end

      private

      def description_change_params
        { approved: params[:data][:approved],
          rejection_reason: params[:data][:rejection_reason] }
      end

      def description_audit_item(validation_request)
        if validation_request.approved?
          { response: "approved" }.to_json
        else
          { response: "rejected", reason: validation_request.rejection_reason }.to_json
        end
      end
    end
  end
end
