# frozen_string_literal: true

Rswag::Ui.configure do |c|
  # c.openapi_endpoint "/submissions/api-docs/v1/swagger_doc.yaml", "Submission API V1 Docs"
  c.openapi_endpoint "/api/docs/v2/swagger_doc.yaml", "Submission API V2 Docs"

  # Rswag::UI doesn't provide a helper for this so we need to set it directly on config hash
  c.config_object[:"urls.primaryName"] = "Submission API Docs"
end
