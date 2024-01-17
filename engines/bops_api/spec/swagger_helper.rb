# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.openapi_strict_schema_validation = true
  config.openapi_root = BopsApi::Engine.root.join("swagger").to_s
  config.openapi_format = :yaml

  json = BopsApi::Schemas.find!("submission").value

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

  definitions = json["definitions"].deep_transform_values(&transformer)
  submission = json.slice(*keys).deep_transform_values(&transformer)

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
