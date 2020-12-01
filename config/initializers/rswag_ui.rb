# frozen_string_literal: true

# /config/initializer/rswag-ui.rb
#
require "rswag/ui"

Rswag::Ui.configure do |c|
  c.swagger_endpoint "api/swagger_doc.json", "Docs"
  c.swagger_endpoint "api/swagger_admin_doc.json", "Admin Docs Internal"
end
