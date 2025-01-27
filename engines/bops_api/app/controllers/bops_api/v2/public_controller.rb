# frozen_string_literal: true

module BopsApi
  module V2
    class PublicController < ApplicationController
      before_action :set_cors_headers

      def set_cors_headers
        response.set_header("Access-Control-Allow-Origin", "*")
        response.set_header("Access-Control-Allow-Methods", "GET")
        response.set_header(
          "Access-Control-Allow-Headers",
          "Origin, X-Requested-With, Content-Type, Accept"
        )
        response.charset = "utf-8"
      end

      private

      def planning_applications_scope
        current_local_authority.planning_applications.published
      end
      def consultation_scope
        current_local_authority.consultations
      end
      def comments_scope
        current_local_authority.neighbour_responses
      end
    end
  end
end
