# frozen_string_literal: true

module BopsApi
  module V2
    class PingController < AuthenticatedController
      def index
        respond_to do |format|
          format.json
        end
      end
    end
  end
end
