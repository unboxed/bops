# frozen_string_literal: true

module BopsApi
  module SchemaValidation
    extend ActiveSupport::Concern

    included do
      delegate :query_parameters, to: :request
      delegate :request_parameters, to: :request
    end

    module ClassMethods
      def validate_schema!(name, **options)
        version = options.delete(:version) || Schemas::ODP_VERSION

        before_action(**options) do
          schema = Schemas.find!(name, version: version)

          unless schema.valid?(request_parameters)
            raise BopsApi::Errors::InvalidRequestError, "We couldn’t process your request because some information is missing or incorrect."
          end
        end
      end
    end
  end
end
