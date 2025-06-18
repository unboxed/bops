# frozen_string_literal: true

module BopsApi
  module NeighbourResponse
    class NeighbourResponseCreationService
      class CreateError < StandardError; end
      def initialize(planning_application:, params:)
        @planning_application = planning_application
        @params = params
      end

      def call
        save_neighbour_response!(build_neighbour_response)
      end

      private

      attr_reader :params, :planning_application

      def build_neighbour_response
        response = planning_application.consultation.neighbour_responses.build(
          response_params.except(:address, :files, :planning_application_id).merge!(
            received_at: Time.zone.now,
            consultation_id: @planning_application.consultation
          )
        )

        response.neighbour = find_or_create_neighbour

        create_files(response) if files_present?

        response
      end

      def find_or_create_neighbour
        neighbour = planning_application.consultation.neighbours.find_by(address: params[:address])

        neighbour.presence || planning_application.consultation.neighbours.build(
          address: params[:address], selected: false, source: "sent_comment"
        )
      end

      def create_files(response)
        params[:files].each do |file|
          planning_application.documents.create!(file:, neighbour_response: response)
        end
      end

      def save_neighbour_response!(neighbour_response)
        neighbour_response.save!

        neighbour_response
      rescue ActiveRecord::RecordInvalid => e
        raise CreateError, e.message
      end

      def response_params
        params.permit(
          :address, :name, :email, :received_at, :response, :new_address, :summary_tag,
          :redacted_response, tags: [], files: []
        )
      end

      def files_present?
        params[:files]&.compact_blank&.any?
      end
    end
  end
end
