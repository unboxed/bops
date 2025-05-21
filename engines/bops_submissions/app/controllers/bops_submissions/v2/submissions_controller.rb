# frozen_string_literal: true

module BopsSubmissions
  module V2
    class SubmissionsController < AuthenticatedController
      def create
        @submission = creation_service.call

        respond_to do |format|
          format.json
        end
      end

      private

      def creation_service
        @creation_service ||= BopsSubmissions::CreationService.new(
          params: params, headers: request.headers, local_authority: current_local_authority
        )
      end
    end
  end
end
