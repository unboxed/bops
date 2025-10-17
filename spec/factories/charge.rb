# frozen_string_literal: true

FactoryBot.define do
  factory :charge do
    planning_application
    description { "Application charge" }
    amount { 100.00 }
    payment_due_date { Time.zone.today + 7.days }
  end
end
