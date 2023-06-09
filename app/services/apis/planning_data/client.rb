# frozen_string_literal: true

require "faraday"

module Apis
  module PlanningData
    class Client
      HOST = "https://www.planning.data.gov.uk"
      TIMEOUT = 5

      def call(query)
        faraday.get("/entity.json?#{query}") do |request|
          request.options[:timeout] = TIMEOUT
        end
      end

      private

      def faraday
        @faraday ||= Faraday.new(url: HOST) do |f|
          f.response :raise_error
        end
      end
    end
  end
end
