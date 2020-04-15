
FactoryBot.define do
  factory :user do
    email { "test@example.com" }
    name { "Test Assessor"}
    password  { "password123" }
  end

  trait :assessor do
    role { "assessor" }
  end

  trait :reviewer do
    role { "reviewer" }
  end

  trait :admin do
    role { "admin" }
  end
end
