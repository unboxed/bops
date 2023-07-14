# frozen_string_literal: true

FactoryBot.define do
  factory :condition do
    title { "The proposal must be built within three years of receiving approval" }
    text { "The development hereby permitted shall begin before the expiration of three years" }

    after(:create) do |condition|
      condition.application_types << create(:application_type, :prior_approval)
    end
  end
end
