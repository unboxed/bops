# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    name { Faker::Name.name }
    subdomain { Faker::Name.name }
  end
end
