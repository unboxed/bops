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
          name, version = schema_name_and_version
          schema = Schemas.find!(name, version:)

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

    def schema_name_and_version
      uri = URI.parse(request_schema)

      case uri.host
      when "theopensystemslab.github.io"
        odp_schema_name_and_version(uri.path)
      else
        raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
      end
    end

    def odp_schema_name_and_version(path)
      case File.basename(path)
      when "schema.json"
        ["submission", "odp/#{File.basename(File.dirname(path))}"]
      when "application.json"
        ["submission", "odp/#{File.basename(File.dirname(path, 2))}"]
      when "preApplication.json"
        ["preApplication", "odp/#{File.basename(File.dirname(path, 2))}"]
      else
        raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
      end
    end
  end
end
