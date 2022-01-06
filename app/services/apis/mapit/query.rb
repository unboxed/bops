# frozen_string_literal: true

require "faraday"

module Apis
  module Mapit
    class Query
      def fetch(postcode)
        response = client.call(postcode)

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
        ward_id = body["shortcuts"]["ward"]
        ward_object = body["areas"][ward_id.to_s]

        [ward_object["type_name"], ward_object["name"]]
      end

      def client
        @client ||= Apis::Mapit::Client.new
      end
    end
  end
end
