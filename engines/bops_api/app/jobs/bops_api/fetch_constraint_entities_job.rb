# frozen_string_literal: true

require "faraday"
require "uri"

module BopsApi
  class FetchConstraintEntitiesJob < ApplicationJob
    queue_as :low_priority
    discard_on ActiveJob::DeserializationError

    def perform(planning_application_constraint, entities)
      planning_application_constraint.update!(data: fetch_entities(entities))
    end

    private

    def fetch_entities(entities)
      entities.map { |entity| fetch_entity(entity.fetch(:source)) }.compact
    end

    def fetch_entity(source)
      return unless entity_url?(source)

      uri = URI.parse(entity_url(source))

      connection = Faraday.new(uri.origin) do |faraday|
        faraday.response :raise_error
        faraday.response :json, content_type: /\bjson$/
      end

      response = connection.get(uri.request_uri)

      unless response.body.is_a?(Hash)
        raise BopsApi::Errors::InvalidEntityResponseError, "Request for entity #{uri} returned a non-JSON response"
      end

      response.body
    rescue Faraday::ResourceNotFound
      nil
    end

    def entity_url(source)
      case source
      when Hash
        "#{source.fetch(:url)}.json"
      when String
        "#{source}.json"
      else
        raise ArgumentError, "Invalid entity source: #{source.inspect}"
      end
    end

    def entity_url?(source)
      case source
      when Hash
        source.fetch(:url, nil).present?
      when String
        source.start_with?("https://www.planning.data.gov.uk/entity")
      else
        false
      end
    end
  end
end
