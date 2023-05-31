# frozen_string_literal: true

FactoryBot.define do
  factory :neighbour_letter do
    sent_at { 1.day.ago }
    status { "submitted" }
    neighbour
  end
end
