# frozen_string_literal: true

require "faraday"

module Apis
  module Mapit
    class Query
      PARISH_TYPES = %w[NCP CPC CPW].freeze

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
        areas = body["areas"]

        ward_id = body["shortcuts"]["ward"]
        ward_object = areas[ward_id.to_s]

        [ward_object["type_name"], ward_object["name"], parish_name(areas)]
      end

      def client
        @client ||= Apis::Mapit::Client.new
      end

      def parish_name(areas)
        parish_object = areas.values.find { |hash| PARISH_TYPES.include?(hash["type"]) }

        parish_object&.fetch("name")
      end
    end
  end
end
