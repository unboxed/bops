FactoryBot.define do
  factory :audit do
    association :user
    planning_application

    activity_type { "approved" }
  end
end
