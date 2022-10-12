# frozen_string_literal: true

FactoryBot.define do
  factory :consultee do
    name { Faker::Name.name }
    origin { :internal }
  end
end
