# frozen_string_literal: true

FactoryBot.define do
  factory :agent do
    name { Faker::Name.unique.name }
    phone { "0719 111111" }
    email { Faker::Internet.email }
  end
end
