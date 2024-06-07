# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

Dir[BopsApi::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.openapi_strict_schema_validation = true
  config.openapi_root = BopsApi::Engine.root.join("swagger").to_s
  config.openapi_format = :yaml

  submission_json = BopsApi::Schemas.find!("submission", version: "odp/v0.6.0").value
  search_json = BopsApi::Schemas.find!("search", version: "odp/v0.6.0").value
  application_submission_json = BopsApi::Schemas.find!("applicationSubmission", version: "odp/v0.6.0").value

  keys = %w[
    additionalProperties
    properties
    required
    type
  ]

  transformer = ->(value) {
    next value unless value.is_a?(String)
    next value unless value.start_with?("#/definitions")

    value.sub("#/definitions/", "#/components/definitions/")
  }

  definitions = submission_json["definitions"].deep_transform_values(&transformer)
  submission = submission_json.slice(*keys).deep_transform_values(&transformer)

  search = search_json.slice(*keys).deep_transform_values(&transformer)

  application_submission = application_submission_json.slice(*keys).deep_transform_values(&transformer)

  config.openapi_specs = {
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

        definitions: definitions,

        schemas: {
          Submission: submission,

          SubmissionResponse: {
            type: "object",
            properties: {
              id: {
                type: "string"
              },
              message: {
                type: "string"
              }
            },
            required: %w[id message]
          },

          Search: search,

          ApplicationSubmission: application_submission,

          Healthcheck: {
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
          },

          BadRequestError: {
            type: "object",
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 400
                  },
                  message: {
                    type: "string",
                    const: "Bad Request"
                  },
                  detail: {
                    type: "string"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error]
          },

          UnauthorizedError: {
            additionalProperties: false,
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
            required: %w[error],
            type: "object"
          },

          ForbiddenError: {
            additionalProperties: false,
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 403
                  },
                  message: {
                    type: "string",
                    const: "Forbidden"
                  },
                  detail: {
                    type: "string"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error],
            type: "object"
          },

          NotFoundError: {
            type: "object",
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 404
                  },
                  message: {
                    type: "string",
                    const: "Not found"
                  },
                  detail: {
                    type: "string"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error]
          },

          UnprocessableEntityError: {
            type: "object",
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 422
                  },
                  message: {
                    type: "string",
                    const: "Unprocessable Entity"
                  },
                  detail: {
                    type: "string"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error]
          },

          InternalServerError: {
            type: "object",
            properties: {
              error: {
                type: "object",
                properties: {
                  code: {
                    type: "integer",
                    const: 500
                  },
                  message: {
                    type: "string",
                    const: "Internal Server Error"
                  },
                  detail: {
                    type: "string"
                  }
                },
                required: %w[code message]
              }
            },
            required: %w[error]
          }
        }
      }
    }
  }
end
