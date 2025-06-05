# frozen_string_literal: true

module BopsApi
  module V2
    class PingController < AuthenticatedController
      def index
        respond_to do |format|
          format.json
        end
      end

      private

      def required_api_key_scope
        :any
      end
    end
  end
end
