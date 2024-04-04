# frozen_string_literal: true

FactoryBot.define do
  factory :term do
    title { "Time limit" }
    text { "The development hereby permitted shall be commenced within three years of the date of this permission." }

    heads_of_term

    trait :skip_validation_request do
      before(:create) do |term|
        term.class.reset_callbacks(:create)
      end
    end
  end
end
