FactoryBot.define do
  factory :description_change_validation_request do
    planning_application
    user
    state { "open" }
    proposed_description { "New description" }
    approved { nil }
    rejection_reason { nil }
  end
end
