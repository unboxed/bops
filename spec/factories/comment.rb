# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    text { Faker::Lorem.paragraph }
    association :commentable, factory: :evidence_group
    user
  end
end
