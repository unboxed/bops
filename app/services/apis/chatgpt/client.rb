# frozen_string_literal: true

require "faraday"

module Apis
  module Chatgpt
    class Client
      def initialize(response)
        @api_key = Rails.configuration.chat_gpt_api_key
        @response = response
      end

      attr_reader :api_key, :response

      def redact_response
        conn = Faraday.new(
          url: "https://api.openai.com/v1",
          headers: {"Authorization" => "Bearer #{api_key}", "Content-Type" => "application/json"}
        )

        response = conn.post("chat/completions") do |req|
          req.body = {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "system",
                content: "Redact sensitive and irrelevant information from responses."
              },
              {
                role: "user",
                content: prompt
              }
            ]
          }.to_json
        end

        JSON.parse(response.body)
      end

      private

      def prompt
        <<~PROMPT
          Review the following response and apply redactions where necessary to protect personal privacy according to these guidelines:
          - Redact all personal names.
          - Redact third-party addresses, personal contact details (like phone numbers and email addresses), and any descriptions that could identify an individual.
          - Redact any information related to an individual's race, beliefs, health, and sexual orientation.
          - Redact offensive language
          Always use '[redacted]' to indicate removed sections. Do not modify the response in any way that alters its original meaning or introduces new information.
      
          Response: '#{response}'
        PROMPT
      end
    end
  end
end
