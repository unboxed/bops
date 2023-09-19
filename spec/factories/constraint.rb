# frozen_string_literal: true

FactoryBot.define do
  factory :constraint do
    type { "designated_conservationarea" }
    category { "heritage_and_conservation" }
    local_authority { nil }

    initialize_with { Constraint.find_or_create_by(type:, category:, local_authority:) }
  end

  trait :listed do
    type { "listed" }
    category { "heritage_and_conservation" }
  end

  trait :tpo do
    type { "tpo" }
    category { "trees" }
  end

  trait :national_park do
    type { "designated_nationalpark" }
    category { "heritage_and_conservation" }
  end
end
