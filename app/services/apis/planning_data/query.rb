# frozen_string_literal: true

require "faraday"

module Apis
  module PlanningData
    class Query
      def fetch(reference)
        response = client.call(reference)

        if response.success?
          parse(JSON.parse(response.body))
        else
          []
        end
      rescue Faraday::ResourceNotFound, Faraday::ClientError
        []
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        []
      end

      private

      def parse(body)
        body["count"] == 1 && body["end-date"].blank? ? body["entities"].first["reference"] : nil
      end

      def client
        @client ||= Apis::PlanningData::Client.new
      end
    end
  end
end
