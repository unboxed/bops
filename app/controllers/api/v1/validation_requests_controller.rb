# frozen_string_literal: true

module Api
  module V1
    class ValidationRequestsController < Api::V1::ApplicationController
      before_action :check_token_and_set_application, only: %i[index], if: :json_request?

      def index; end

      private

      def check_file_size
        if params[:new_file].size > 30.megabytes
          render json: { message: "The file must be 30MB or less" }, status: :bad_request
        end
      end

      def check_file_type
        unless Document::PERMITTED_CONTENT_TYPES.include? params[:new_file].content_type
          render json: { message: "The file type must be JPEG, PNG or PDF" }, status: :bad_request
        end
      end

      def unauthorized_response
        render json: {}, status: :unauthorized
      end

      def render_failed_request
        render json: { message: "Validation request could not be updated - please contact support" }, status: :bad_request
      end
    end
  end
end
