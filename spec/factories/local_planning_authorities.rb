FactoryBot.define do
  factory :local_planning_authority do
    name { "Test Authority" }
    sequence(:subdomain) { |n| "test#{n}" }
  end
end
