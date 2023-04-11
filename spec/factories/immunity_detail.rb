# frozen_string_literal: true

FactoryBot.define do
  factory :immunity_detail do
    planning_application
    end_date { 5.years.ago }
  end
end
