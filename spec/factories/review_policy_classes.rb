# frozen_string_literal: true

FactoryBot.define do
  factory :review_policy_class do
    policy_class
    mark { "accept" }
    status { "not_checked_yet" }
  end
end
