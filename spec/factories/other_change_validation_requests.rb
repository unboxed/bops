FactoryBot.define do
  factory :other_change_validation_request do
    planning_application
    user
    state { "open" }
    summary { "Incorrect fee" }
    suggestion { "You need to pay a different fee" }
  end
end
