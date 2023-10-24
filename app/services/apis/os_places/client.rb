# frozen_string_literal: true

require "faraday"

module Apis
  module OsPlaces
    class Client
      BASE_URL = "https://api.os.uk/search/places/v1/"
      TIMEOUT = 5

      def get(endpoint, params)
        faraday.get(endpoint) do |request|
          request.params = params.merge(key)
        end
      end

      def post(body, params)
        response = faraday.post("polygon") do |request|
          request.params = params.merge(key)
          request.headers["Content-Type"] = "application/json"
          request.body = body.to_json
        end

        data = JSON.parse(response.body)
        data["results"]&.map { |result| result["DPA"]["ADDRESS"] } || []
      end

      private

      def key
        {key: Rails.configuration.os_vector_tiles_api_key}
      end

      def faraday
        @faraday ||= Faraday.new(url: BASE_URL) do |f|
          f.options[:timeout] = TIMEOUT
          f.response :raise_error
        end
      end
    end
  end
end
