# frozen_string_literal: true

FactoryBot.define do
  factory :consultation do
    planning_application

    trait :started do
      start_date { 2.days.ago }
      end_date { 2.days.ago + 21.days }
    end
  end
end
