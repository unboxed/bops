# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def example_fixture(name, version: BopsApi::Schemas::DEFAULT_ODP_VERSION, **)
      JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", version, name).read, **)
    end

    def load_and_resolve_schema(name:, version:)
      schema = BopsApi::Schemas.find!(name, version: version).value
      definitions = BopsApi::Schemas.find!("shared/definitions", version: version).value

      resolve_references(schema, definitions)
    end

    private

    def resolve_references(schema, definitions)
      schema["properties"].transform_values! do |value|
        if value.is_a?(Hash) && value["$ref"]
          ref = value["$ref"]
          if ref.start_with?("#/definitions/")
            definition_key = ref.sub("#/definitions/", "")
            definitions["definitions"][definition_key] || value
          else
            value
          end
        else
          value
        end
      end
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
