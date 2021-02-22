FactoryBot.define do
  factory :audit do
    association :user_id, factory: :user
    planning_application

    activity_type { "approved" }
  end
end
