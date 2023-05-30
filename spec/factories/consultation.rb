# frozen_string_literal: true

FactoryBot.define do
  factory :consultation do
    start_date { 2.days.ago }
    planning_application
  end
end
