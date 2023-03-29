# frozen_string_literal: true

require "faraday"

module Apis
  module Bops
    class Query
      def fetch(local_authority, planning_application)
        response = client.call(local_authority, planning_application)
      rescue Faraday::ClientError
        []
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        []
      end

      private

      def client
        @client ||= Apis::Bops::Client.new
      end
    end
  end
end
