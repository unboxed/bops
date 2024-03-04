# frozen_string_literal: true

FactoryBot.define do
  factory :informative do
    planning_application

    title { "Section 106 undertaking" }
    text { "This planning permission is pursuant to a planning obligation under Section 106 of the Town and Country Planning Act 1990." }
  end
end
