# frozen_string_literal: true

require "faraday"

module Apis
  module Paapi
    TIMEOUT = 5

    class << self
      def fetch(uprn)
        return [] if Rails.configuration.paapi_url.blank?

        client = Faraday.new(url: Rails.configuration.paapi_url, request: {timeout: TIMEOUT}) do |f|
          f.response :raise_error
        end

        response = client.get("planning_applications/", uprn:)

        JSON.parse(response.body)["data"]
      rescue Faraday::ResourceNotFound, Faraday::ClientError
        []
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        []
      end
    end
  end
end
