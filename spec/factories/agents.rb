# frozen_string_literal: true

FactoryBot.define do
  factory :agent do
    name { Faker::Name.unique.name }
    phone { Faker::Base.numerify("+44 7### ######") }
    email { Faker::Internet.email }
  end
end
