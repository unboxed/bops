# frozen_string_literal: true

require "faraday"

module Apis
  module OsPlaces
    class Query
      def get(query)
        client.call(query)
      rescue Faraday::ClientError
        []
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        []
      end

      private

      def client
        @client ||= Apis::OsPlaces::Client.new
      end
    end
  end
end
