# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.swagger_root = BopsApi::Engine.root.join("swagger").to_s
end
