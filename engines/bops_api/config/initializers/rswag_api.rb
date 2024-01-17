# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.openapi_root = BopsApi::Engine.root.join("swagger").to_s
end
