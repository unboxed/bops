# frozen_string_literal: true

FactoryBot.define do
  factory :condition do
    title { "Time limit" }
    text { "The development herby permitted shall be commenced within three years of the date of this permission." }
    reason { "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)." }
  end
end
