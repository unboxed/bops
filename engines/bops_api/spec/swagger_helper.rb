# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.swagger_strict_schema_validation = true
  config.swagger_root = BopsApi::Engine.root.join("swagger").to_s
  config.swagger_format = :yaml

  config.swagger_docs = {
    "v2/swagger_doc.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Back-office Planning System",
        version: "v2"
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer"
          }
        },

        schemas: {
          unauthorized: {
            type: "object",
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 401
                  },
                  message: {
                    type: "string",
                    const: "Unauthorized"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error]
          },

          healthcheck: {
            type: "object",
            properties: {
              message: {
                type: "string",
                const: "OK"
              },
              timestamp: {
                type: "string",
                format: "date-time"
              }
            },
            required: %w[message timestamp]
          }
        }
      }
    }
  }
end