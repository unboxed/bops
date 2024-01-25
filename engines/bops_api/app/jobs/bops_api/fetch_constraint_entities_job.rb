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
      entities.map { |entity| fetch_entity(entity) }
    end

    def fetch_entity(entity)
      uri = URI.parse(entity_url(entity))

      connection = Faraday.new(uri.origin) do |faraday|
        faraday.response :raise_error
        faraday.response :json, content_type: /\bjson$/
      end

      response = connection.get(uri.request_uri)

      unless response.body.is_a?(Hash)
        raise BopsApi::Errors::InvalidEntityResponseError, "Request for entity #{uri} returned a non-JSON response"
      end

      response.body
    end

    def entity_url(entity)
      "#{entity.fetch(:source)}.json"
    end
  end
end
