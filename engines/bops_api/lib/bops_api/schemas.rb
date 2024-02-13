# frozen_string_literal: true

module BopsApi
  class Schemas
    ODP_VERSIONS = {
      "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.2.1/schema.json" => "odp/v0.2.1",
      "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.2.2/schema.json" => "odp/v0.2.2",
      "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.2.3/schema.json" => "odp/v0.2.3",
      "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.3.0/schema.json" => "odp/v0.3.0"
    }.freeze

    DEFAULT_ODP_VERSION = "odp/v0.3.0"

    class << self
      def find!(name, version: nil, schema: nil)
        cache.find!("#{version || ODP_VERSIONS.fetch(schema)}/#{name}.json")
      rescue KeyError
        raise BopsApi::Errors::SchemaNotFoundError, "Unable to find schema '#{schema}'"
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
