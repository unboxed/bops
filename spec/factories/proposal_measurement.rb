# frozen_string_literal: true

FactoryBot.define do
  factory :proposal_measurement do
    max_height { 2.0 }
    eaves_height { 2.0 }
    depth { 2.0 }
  end
end
