# frozen_string_literal: true

require "faraday"

module Apis
  module PlanningData
    class Query
      def fetch(reference, datasets = [])
        datasets = [datasets] unless datasets.is_a? Enumerable
        query = "reference=#{reference}&" + datasets.map { |dataset| "dataset=#{dataset}" }.join("&")
        response = client.call(query)

        if response.success?
          JSON.parse(response.body, symbolize_names: true)
        else
          {}
        end
      rescue Faraday::ResourceNotFound, Faraday::ClientError
        {}
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        {}
      end

      def council_code(reference)
        body = fetch(reference, ["local-authority"])
        (body[:count] == 1 && body[:"end-date"].blank?) ? body[:entities].first[:reference] : nil
      end

      private

      def client
        @client ||= Apis::PlanningData::Client.new
      end
    end
  end
end
