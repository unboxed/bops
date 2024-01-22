# frozen_string_literal: true

require "faraday"

module Apis
  module OsPlaces
    class Query
      MAX_RESULTS = 20
      SRS = "EPSG:27700" # https://epsg.io/27700

      def find_addresses(query)
        handle_request { client.get("find", find_addresses_params(query)) }
      end

      def find_addresses_by_polygon(body, uprn)
        handle_request { client.post(body, find_addresses_by_polygon_params, uprn) }
      end

      private

      def handle_request
        yield
      rescue Faraday::ClientError => e
        Rails.logger.debug e.message
        Rails.logger.debug e.response
        []
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        []
      end

      def client
        @client ||= Apis::OsPlaces::Client.new
      end

      def find_addresses_params(query)
        {
          maxresults: MAX_RESULTS,
          query:
        }
      end

      def find_addresses_by_polygon_params
        {
          output_srs: SRS,
          srs: SRS
        }
      end
    end
  end
end
