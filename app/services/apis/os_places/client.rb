# frozen_string_literal: true

require "faraday"

module Apis
  module OsPlaces
    class Client
      TIMEOUT = 5

      def call(query)
        faraday(query).get do |request|
          request.options[:timeout] = TIMEOUT
        end
      end

      private

      def faraday(query)
        @faraday ||= Faraday.new(url: "https://api.os.uk/search/places/v1/find?maxresults=20&query=#{query}&key=#{Rails.configuration.os_vector_tiles_api_key}")
      end
    end
  end
end
