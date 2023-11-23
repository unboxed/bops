# frozen_string_literal: true

Rswag::Ui.configure do |c|
  c.swagger_endpoint "/api/docs/v1/swagger_doc.yaml", "API V1 Docs"

  # Rswag::UI doesn't provide a helper for this so we need to set it directly on config hash
  c.config_object[:"urls.primaryName"] = "API V1 Docs"
end
