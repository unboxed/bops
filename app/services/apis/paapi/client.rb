# frozen_string_literal: true

require "faraday"

module Apis
  module Paapi
    class Client
      HOST = ENV.fetch("PAAPI_URL", "https://staging.paapi.services/api/v1").freeze
      TIMEOUT = 5

      def call(uprn)
        faraday.get("planning_applications/?uprn=#{uprn}") do |request|
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
