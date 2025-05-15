# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

Dir[BopsSubmissions::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.openapi_root = BopsSubmissions::Engine.root.join("swagger").to_s
  config.openapi_format = :yaml

  config.openapi_specs = {
    "v2/swagger_doc.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "BOPS Submissions API",
        version: "v2"
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer
          }
        },
        schemas: {
          SubmissionResponse: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid}
            },
            required: ["id"]
          },
          SubmissionEvent: {
            type: :object,
            properties: {
              applicationRef: {type: :string},
              applicationVersion: {type: :integer},
              applicationState: {type: :string},
              sentDateTime: {type: :string, format: :date_time},
              updated: {type: :boolean},
              documentLinks: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    documentName: {type: :string},
                    documentLink: {type: :string, format: :uri},
                    expiryDateTime: {type: :string, format: :date_time},
                    documentType: {type: :string}
                  },
                  required: %w[documentName documentLink documentType]
                }
              }
            },
            required: %w[applicationRef applicationVersion applicationState sentDateTime updated]
          },
          UnprocessableEntityError: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: {type: :integer, example: 422},
                  message: {type: :string, example: "Unprocessable Entity"},
                  detail: {type: :string}
                },
                required: ["code", "message"]
              }
            },
            required: ["error"]
          }
        }
      }
    }
  }

  puts "✅ Loaded swagger_helper from: #{__FILE__}"
  puts "✅ Rswag openapi_specs keys: #{config.openapi_specs.keys.inspect}"
end
