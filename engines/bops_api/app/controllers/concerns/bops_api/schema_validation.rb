# frozen_string_literal: true

module BopsApi
  module SchemaValidation
    extend ActiveSupport::Concern

    included do
      delegate :query_parameters, to: :request
      delegate :request_parameters, to: :request
    end

    module ClassMethods
      def validate_schema!(name, **)
        before_action(**) do
          schema = Schemas.find!(name, schema: request_schema)

          unless schema.valid?(request_parameters)
            raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
          end
        end
      end
    end

    def request_metadata
      request_parameters.fetch("metadata")
    rescue KeyError
      raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
    end

    def request_schema
      request_metadata.fetch("schema")
    rescue KeyError
      raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
    end
  end
end
