# frozen_string_literal: true

require "faraday"

module Apis
  module OsMap
    class ProxyService
      BASE_URL = "https://api.os.uk"

      def initialize(request, response, local_authority)
        @request = request
        @response = response
        @local_authority = local_authority
      end

      def proxy
        faraday_response = fetch_from_os(os_url)
        configure_response_headers
        faraday_response
      end

      def cors_allowed?
        return true if origin.nil? # Same-origin requests are allowed

        return true if origin == local_authority.applicants_url

        Rails.logger.warn "CORS denied for origin: #{origin}"
        false
      end

      private

      attr_reader :request, :response, :local_authority

      def os_url
        os_path = request.fullpath.sub("/map_proxy", "")
        "#{BASE_URL}#{os_path}"
      end

      def fetch_from_os(url)
        faraday.get do |req|
          req.url url
          req.params = request.query_parameters
          req.headers["key"] = Rails.configuration.os_vector_tiles_api_key
          req.headers["Accept"] = "application/octet-stream"
        end
      end

      def configure_response_headers
        response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
        response.headers["Access-Control-Allow-Origin"] = origin if cors_allowed? && origin.present?
      end

      def origin
        request.headers["Origin"]
      end

      def faraday
        @faraday ||= Faraday.new do |f|
          f.response :raise_error
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
