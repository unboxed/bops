# frozen_string_literal: true

require "faraday"

module Apis
  module Mapit
    class Client
      HOST = "https://mapit.mysociety.org"
      ENDPOINT = "postcode/%s"
      TIMEOUT = 5

      def call(postcode)
        faraday.get(path(postcode)) do |request|
          request.options[:timeout] = TIMEOUT
        end
      end

      private

      def faraday
        @faraday ||= Faraday.new(url: HOST) do |f|
          f.response :raise_error
        end
      end

      def path(postcode)
        format(ENDPOINT, postcode.gsub(/\s+/, "").upcase)
      end
    end
  end
end
