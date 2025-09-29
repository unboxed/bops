# frozen_string_literal: true

FactoryBot.define do
  factory :site_history do
    planning_application

    reference { "REF123" }
    description { "An entry for planning history" }
    date { "10/02/1980" }
    decision { :granted }
    comment { "A comment about relevance of planning history" }

    trait :refused do
      reference { "REF456" }
      description { "An entry for planning history that was refused" }
      date { "11/01/2008" }
      decision { :refused }
      comment { "Neighbouring property work of size and scale which was previously refused" }
    end
  end
end
