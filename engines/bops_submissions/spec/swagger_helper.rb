# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

Dir[BopsSubmissions::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.openapi_root = BopsSubmissions::Engine.root.join("swagger").to_s
  config.openapi_format = :yaml

  config.openapi_specs = {
    "v2/submissions/swagger_doc.yaml" => {
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
              uuid: {type: :string, format: :uuid},
              message: {type: :string}
            },
            required: ["uuid"]
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
          },
          UnauthorizedError: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: {type: :integer, example: 401},
                  message: {type: :string, example: "Unauthorized"},
                  detail: {type: :string}
                },
                required: ["code", "message"]
              }
            },
            required: ["error"]
          },
          BadRequestError: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: {type: :integer, example: 400},
                  message: {type: :string, example: "Bad Request"},
                  detail: {type: :string}
                },
                required: ["code", "message"]
              }
            },
            required: ["error"]
          },
          NotFoundError: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: {type: :integer, example: 404},
                  message: {type: :string, example: "Not Found"},
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
end
