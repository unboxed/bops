# frozen_string_literal: true

FactoryBot.define do
  factory :local_policy_area do
    area { "Design" }
    policies { "Policy 1, Policy 2" }
    guidance { "Local policy 1" }
    assessment { "This is fine" }

    local_policy
  end
end
