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

      def check_files_params_are_present
        return unless file_params.empty?

        render json: {message: "At least one file must be selected to proceed."}, status: :bad_request
      end

      def check_files_size
        return if file_params.blank?

        file_params.each do |file|
          next unless file_size_over_30mb?(file)

          render json: {message: "The file: '#{file.original_filename}' exceeds the limit of 30mb. " \
                                  "Each file must be 30MB or less"},
            status: :payload_too_large
        end
      end

      def check_files_type
        return if file_params.blank?
        return unless file_params.any? { |file| Document::PERMITTED_CONTENT_TYPES.exclude? file.content_type }

        render json: {message: "The file type must be JPEG, PNG or PDF"}, status: :bad_request
      end
    end
  end
end
