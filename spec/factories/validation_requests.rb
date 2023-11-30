# frozen_string_literal: true

FactoryBot.define do
  factory :validation_request do
    planning_application
    user
    type { "OtherChangeValidationRequest" }
  end
end
