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

    def with_search_and_filter_params
      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      parameter name: "q",
        in: :query,
        description: "Search by reference, address or description",
        required: false,
        schema: {
          type: :string
        }

      parameter name: "applicationStatus[]",
        in: :query,
        description: "Filter by one or more application statuses",
        style: :form,
        explode: true,
        schema: {
          type: :array,
          items: {
            type: :string
          }
        }

      parameter name: "applicationType[]",
        in: :query,
        description: "Filter by one or more application type codes",
        style: :form,
        explode: true,
        schema: {
          type: :array,
          items: {
            type: :string
          }
        }

      parameter name: :receivedAtFrom,
        in: :query,
        required: false,
        description: "Received at from date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :receivedAtTo,
        in: :query,
        required: false,
        description: "Received at to date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :validatedAtFrom,
        in: :query,
        required: false,
        description: "Validated at from date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :validatedAtTo,
        in: :query,
        required: false,
        description: "Validated at to date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :publishedAtFrom,
        in: :query,
        required: false,
        description: "Published at from date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :publishedAtTo,
        in: :query,
        required: false,
        description: "Published at to date in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :consultationEndDateFrom,
        in: :query,
        required: false,
        description: "Consultation end date from in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :consultationEndDateTo,
        in: :query,
        required: false,
        description: "Consultation end date to in yyyy-mm-dd format",
        schema: {
          type: :string,
          format: :date
        }

      parameter name: :orderBy,
        in: :query,
        description: "Sort by ascending or descending order",
        schema: {
          type: :string,
          required: false,
          enum: ["asc", "desc"],
          default: "desc"
        }

      parameter name: :sortBy,
        in: :query,
        description: "Sort by field",
        schema: {
          type: :string,
          required: false,
          enum: ["publishedAt", "receivedAt"],
          default: "receivedAt"
        }
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
