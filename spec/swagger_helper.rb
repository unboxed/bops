# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'
  config.swagger_docs = {
      'api/swagger_doc.json' => {
          swagger: '2.0',
          info: {
              title: 'Back-office Planning System',
              version: 'v1'
          },
          securityDefinitions: {
              Token: {
                  description: "...",
                  type: :bearer,
                  name: 'Authorization',
                  in: :header
              }
          },
          host: "southwark.lvh.me:3000",
          paths: {}
      }
  }
end
