# frozen_string_literal: true

FactoryBot.define do
  factory :api_user do
    name { Faker::Name.name }
  end
end
