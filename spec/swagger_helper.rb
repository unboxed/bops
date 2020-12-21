# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s
  config.swagger_format = :yaml
  config.swagger_docs = {
      '/v1/swagger_doc.yaml' => {
          openapi: '3.0.1',
          info: {
              title: 'Back-office Planning System',
              version: 'v1'
          },
          components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                }
            }
          },
          paths: {}
      }
  }
end
