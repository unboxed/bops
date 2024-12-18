# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_policy_guidance, class: "LocalAuthority::PolicyGuidance" do
    local_authority
    description { Faker::Lorem.unique.sentence }
  end
end
