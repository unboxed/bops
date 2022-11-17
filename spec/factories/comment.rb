# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    text { Faker::Lorem.paragraph }
    association :commentable, factory: :policy
    user
  end
end
