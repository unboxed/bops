# frozen_string_literal: true

require "faraday"

module Apis
  module Bops
    class Client
      TIMEOUT = 5

      def call(local_authority, planning_application)
        faraday(local_authority).post("planning_applications") do |request|
          request.options[:timeout] = TIMEOUT
          request.body = JSON.parse(planning_application.params_v1).merge("send_email" => "false",
            "from_production" => "true").to_json
        end
      end

      private

      def faraday(local_authority)
        @faraday ||= Faraday.new(url: "https://#{local_authority}.#{Rails.configuration.staging_api_url}") do |f|
          f.response :raise_error
          f.headers = {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{Rails.configuration.staging_api_bearer}"
          }
        end
      end
    end
  end
end
