# frozen_string_literal: true

# /config/initializer/rswag-ui.rb
#
require "rswag/ui"

Rswag::Ui.configure do |c|
  c.swagger_endpoint "/api-docs/v1/_build/swagger_doc.yaml", "Docs"
end
