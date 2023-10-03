# frozen_string_literal: true

FactoryBot.define do
  factory :consideration do
    area { "Design" }
    policies { "Policy 1, Policy 2" }
    guidance { "Local policy 1" }
    assessment { "This is fine" }

    policy_area
  end
end
