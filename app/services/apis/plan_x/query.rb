# frozen_string_literal: true

require "faraday"

module Apis
  module PlanX
    class Query
      def fetch(**args)
        client.call(**args) => {response:, **query_details}

        if response&.success?
          JSON.parse(response.body, symbolize_names: true).merge(query_details)
        else
          {}
        end
      rescue Faraday::ResourceNotFound, Faraday::ClientError
        {}
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        {}
      end

      private

      def client
        @client ||= Apis::PlanX::Client.new
      end
    end
  end
end