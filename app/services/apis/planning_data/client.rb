# frozen_string_literal: true

require "faraday"

module Apis
  module PlanningData
    class Client
      HOST = "https://www.planning.data.gov.uk"
      TIMEOUT = 5

      def get(query)
        faraday.get("/entity.json?#{query}")
      end

      def get_entity_geojson(query)
        faraday.get("/entity/#{query}.geojson")
      end

      private

      def faraday
        @faraday ||= Faraday.new(url: HOST) do |f|
          f.options[:timeout] = TIMEOUT
          f.response :raise_error
        end
      end
    end
  end
end
