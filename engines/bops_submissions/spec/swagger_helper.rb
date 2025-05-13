# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/submissions.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'BOPS Submissions API',
        version: 'v1'
      },
      paths: {}
    }
  }

  config.swagger_format = :yaml
end
