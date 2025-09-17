# frozen_string_literal: true

module BopsSubmissions
  class CreationService
    HEADERS = %w[
      User-Agent
      Content-Type
      Accept
      X-Request-Id
      X-Forwarded-For
      X-Real-IP
      Host
      Referer
    ].freeze

    def initialize(params:, headers:, local_authority:, schema: nil)
      @params = params
      @headers = headers
      @local_authority = local_authority
      @schema = schema
    end

    attr_reader :params, :headers, :local_authority, :schema

    def call
      submission = local_authority.submissions.create!(
        request_headers: filtered_request_headers,
        request_body: params,
        schema:
      )

      submission.update!(external_uuid: SecureRandom.uuid_v7)
      submission
    end

    private

    def filtered_request_headers
      headers.env.select do |key, _|
        key.start_with?("HTTP_") || ["CONTENT_TYPE", "CONTENT_LENGTH"].include?(key)
      end.transform_keys do |key|
        key.sub(/^HTTP_/, "").split("_").map(&:capitalize).join("-")
      end.slice(*HEADERS)
    end
  end
end
