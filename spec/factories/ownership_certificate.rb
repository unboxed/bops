# frozen_string_literal: true

FactoryBot.define do
  factory :ownership_certificate do
    planning_application

    certificate_type { "B" }
  end
end
