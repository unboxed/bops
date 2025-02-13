# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    sequence(:section, "A")
    sequence(:name) { |n| "Class Name #{n}" }
    url { "http://example.com" }

    association :policy_part
  end
end
