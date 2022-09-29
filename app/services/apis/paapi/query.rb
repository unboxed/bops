# frozen_string_literal: true

require "faraday"

module Apis
  module Paapi
    class Query
      def fetch(uprn)
        response = client.call(uprn)

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
        body["data"]
      end

      def client
        @client ||= Apis::Paapi::Client.new
      end
    end
  end
end
