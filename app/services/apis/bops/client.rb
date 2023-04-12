# frozen_string_literal: true

require "faraday"

module Apis
  module Bops
    class Client
      HOST = ENV.fetch("STAGING_API_URL").freeze
      TIMEOUT = 5

      def call(local_authority, planning_application)
        faraday(local_authority).post("planning_applications") do |request|
          request.options[:timeout] = TIMEOUT
          request.body = JSON.parse(planning_application.audit_log).merge("send_email" => "false",
                                                                          "from_production" => "true").to_json
        end
      end

      private

      def faraday(local_authority)
        @faraday ||= Faraday.new(url: "https://#{local_authority}.#{HOST}") do |f|
          f.response :raise_error
          f.headers = {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{ENV.fetch('STAGING_API_BEARER')}"
          }
        end
      end
    end
  end
end
