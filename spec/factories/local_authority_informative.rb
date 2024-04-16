# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_informative do
    local_authority
    title { Faker::Lorem.sentence }
    text { Faker::Lorem.paragraph }
  end
end
