# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    planning_application
    user

    entry { "I am a note" }
  end
end
