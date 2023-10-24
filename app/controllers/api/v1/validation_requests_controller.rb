# frozen_string_literal: true

module Api
  module V1
    class ValidationRequestsController < Api::V1::ApplicationController
      before_action :check_token_and_set_application, only: %i[index], if: :json_request?

      def index
      end

      private

      def unauthorized_response
        render json: {}, status: :unauthorized
      end

      def render_failed_request
        render json: {message: "Validation request could not be updated - please contact support"},
          status: :bad_request
      end

      def file_size_over_30mb?(file)
        file.size > 30.megabytes
      end
    end
  end
end
