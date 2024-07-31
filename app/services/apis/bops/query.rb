# frozen_string_literal: true

require "faraday"

module Apis
  module Bops
    class Query
      def post(local_authority, submission)
        client.call(local_authority, submission)
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
