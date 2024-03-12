# frozen_string_literal: true

FactoryBot.define do
  factory :committee_decision do
    recommend { false }
    planning_application
  end
end
