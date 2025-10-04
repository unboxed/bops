# frozen_string_literal: true

FactoryBot.define do
  factory :consultee_constraint do
    consultee { association :contact }
    constraint { association :constraint }
  end
end
