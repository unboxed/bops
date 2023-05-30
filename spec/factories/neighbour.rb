# frozen_string_literal: true

FactoryBot.define do
  factory :neighbour do
    name { "Lisa Puddle" }
    address { "123, Made Up Street, London, W5 67S" }
    consultation
  end
end
