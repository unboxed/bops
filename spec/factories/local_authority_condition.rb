# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_condition, class: "LocalAuthority::Condition" do
    local_authority
    title { Faker::Lorem.sentence }
    text { Faker::Lorem.paragraph }
    reason { Faker::Lorem.paragraph }
  end
end
