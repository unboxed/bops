# frozen_string_literal: true

FactoryBot.define do
  factory :meeting do
    association :created_by, factory: :user
    planning_application

    comment { "A comment about the meeting" }
    occurred_at { 1.day.ago }
  end
end
