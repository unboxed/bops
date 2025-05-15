# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.openapi_root = BopsSubmissions::Engine.root.join("swagger").to_s
end
