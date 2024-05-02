# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_policy_reference, class: LocalAuthority::PolicyReference do
    local_authority
    code { Faker::IDNumber.unique.ssn_valid }
    description { Faker::Lorem.unique.sentence }
  end
end
