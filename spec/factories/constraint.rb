# frozen_string_literal: true

FactoryBot.define do
  factory :constraint do
    name { "Flood zone" }
    category { "flooding" }
    local_authority { nil }

    initialize_with { Constraint.find_or_create_by(name:, category:, local_authority:) }
  end
end
