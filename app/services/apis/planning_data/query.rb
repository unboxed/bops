# frozen_string_literal: true

require "faraday"

module Apis
  module PlanningData
    class Query
      def get_council_code(reference)
        body = query_entity(reference, ["local-authority"])
        (body[:count] == 1 && body[:"end-date"].blank?) ? body[:entities].first[:reference] : nil
      end

      def get_entity_geojson(reference)
        handle_request { client.get_entity_geojson(reference) }
      end

      private

      def query_entity(reference, datasets = [])
        handle_request { client.get(query(reference, datasets)) }
      end

      def handle_request
        response = yield
        response.success? ? parse_response(response) : {}
      rescue Faraday::ResourceNotFound, Faraday::ClientError => e
        Rails.logger.debug e.message
        Rails.logger.debug e.response
        {}
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        {}
      end

      def client
        @client ||= Apis::PlanningData::Client.new
      end

      def query(reference, datasets)
        [reference_query(reference), dataset_query(datasets)].join("&")
      end

      def reference_query(reference)
        "reference=#{reference}"
      end

      def dataset_query(datasets)
        Array(datasets).map { |dataset| "dataset=#{dataset}" }.join("&")
      end

      def parse_response(response)
        JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError => e
        Rails.logger.debug e.message
        {}
      end
    end
  end
end
