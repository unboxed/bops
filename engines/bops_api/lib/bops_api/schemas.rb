# frozen_string_literal: true

module BopsApi
  class Schemas
    DEFAULT_ODP_VERSION = "odp/v0.7.4"

    class << self
      def find!(name, version: nil)
        cache.find!("#{version || DEFAULT_ODP_VERSION}/#{name}.json")
      rescue KeyError
        raise BopsApi::Errors::SchemaNotFoundError, "Unable to find schema '#{version}/#{name}'"
      end

      private

      def cache
        @cache ||= Schemas.new
      end
    end

    def initialize
      @schemas = Concurrent::Map.new
      @schema_path = BopsApi::Engine.root.join("schemas")
    end

    def find!(file)
      return schemas[file] if schemas.key?(file)

      path = schema_path.join(file)

      unless path.exist?
        raise BopsApi::Errors::SchemaNotFoundError, "Unable to find schema '#{file}'"
      end

      begin
        load_schema(path).tap do |schema|
          schemas[file] = schema
        end
      rescue
        raise BopsApi::Errors::InvalidSchemaError, "Unable to load schema '#{file}'"
      end
    end

    private

    attr_reader :schemas, :schema_path

    def load_schema(path)
      JSONSchemer.schema(JSON.parse(File.read(path)))
    end
  end
end
