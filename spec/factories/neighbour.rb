# frozen_string_literal: true

FactoryBot.define do
  factory :neighbour do
    address { Faker::Address.full_address }
    consultation
  end
end
