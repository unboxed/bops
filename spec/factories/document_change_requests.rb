FactoryBot.define do
  factory :document_change_request do
    planning_application
    user
    old_document factory: :document
    new_document factory: :document
    state { "open" }
  end
end
