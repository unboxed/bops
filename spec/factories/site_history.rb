# frozen_string_literal: true

FactoryBot.define do
  factory :site_history do
    planning_application

    application_number { "REF123" }
    description { "An entry for planning history" }
    date { "10/02/1980" }
    decision { :granted }
  end
end
