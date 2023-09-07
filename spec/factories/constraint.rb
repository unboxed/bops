# frozen_string_literal: true

FactoryBot.define do
  factory :constraint do
    type { "flood_zone" }
    category { "flooding" }
    local_authority { nil }

    initialize_with { Constraint.find_or_create_by(type:, category:, local_authority:) }
  end
end
