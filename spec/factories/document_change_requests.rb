FactoryBot.define do
  factory :document_change_request do
    planning_application
    user
    document
    state { "open" }
    approved { nil }
    rejection_reason { nil }
  end
end
