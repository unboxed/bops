# frozen_string_literal: true

require "faraday"

module Apis
  module OsPlaces
    class PolygonSearchService < Client
      RESULTS_PER_PAGE = 100
      MAX_TOTAL_RESULTS = 1000

      attr_reader :all_addresses

      def initialize(body, params, uprn)
        @body = body
        @params = params
        @uprn = uprn
        @all_addresses = []
        @offset = 0
      end

      def call
        fetch_all_addresses

        {total_results: @total_results, addresses: all_addresses}
      end

      private

      attr_reader :body, :params, :uprn, :offset, :total_results

      def fetch_all_addresses
        loop do
          handle_response(post_request)
          break if end_of_results? || search_limit_reached?
          update_offset
        end
      end

      def post_request
        faraday.post("polygon") do |request|
          request.params = current_params
          request.headers["Content-Type"] = "application/json"
          request.body = body.to_json
        end
      end

      def handle_response(response)
        data = JSON.parse(response.body)
        @total_results = total_results_from_response(data) if offset.zero?
        all_addresses.concat(retrieve_addresses(data))
      end

      def current_params
        params.merge(offset:)
      end

      def retrieve_addresses(data)
        results = data["results"] || []

        results.each_with_object([]) do |result, addresses|
          if uprn.present? && result["DPA"]["UPRN"] == uprn
            @total_results -= 1
          else
            addresses << result["DPA"]["ADDRESS"]
          end
        end
      end

      def end_of_results?
        RESULTS_PER_PAGE * (offset / RESULTS_PER_PAGE + 1) >= total_results
      end

      def total_results_from_response(data)
        data.dig("header", "totalresults").to_i
      end

      def search_limit_reached?
        all_addresses.length >= MAX_TOTAL_RESULTS
      end

      def update_offset
        @offset += RESULTS_PER_PAGE
      end
    end
  end
end
