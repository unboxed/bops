# frozen_string_literal: true

Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api/docs/v2/swagger_doc.yaml", "API V2 Docs"

  c.config_object.merge!(
    persistAuthorization: true,
    requestSnippetsEnabled: true,
    requestSnippets: {
      defaultExpanded: false,
      languages: ["curl_bash"]
    }
  )
end
