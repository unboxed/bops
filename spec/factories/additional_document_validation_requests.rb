FactoryBot.define do
  factory :additional_document_validation_request do
    planning_application
    user
    new_document factory: :document
    state { "open" }
    document_request_type { "Floor plan" }
    document_request_reason { "Missing floor plan" }
  end
end
