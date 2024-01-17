# frozen_string_literal: true

module BopsApi
  class Schemas
    ODP_VERSION = "odp/v0.2.2"

    class << self
      def find!(name, version: ODP_VERSION)
        cache.find!("#{version}/#{name}.json")
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
