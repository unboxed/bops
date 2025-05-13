# frozen_string_literal: true

module BopsSubmissions
  module V1
    class SubmissionsController < AuthenticatedController
      def create
        @uuid = creation_service.call

        respond_to do |format|
          format.json
        end
      end

      private

      def creation_service
        @creation_service ||= BopsSubmissions::CreationService.new(
          request: request, local_authority: current_local_authority
        )
      end
    end
  end
end
