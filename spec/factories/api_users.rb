# frozen_string_literal: true

FactoryBot.define do
  factory :api_user do
    name { Faker::Name.name }
    service { "PlanX" }

    file_downloader do
      {
        "type" => "HeaderAuthentication",
        "key" => "api-key",
        "value" => "G41sAys9uPMUVBH5WUKsYE4H"
      }
    end

    trait :swagger do
      name { "swagger" }
    end

    trait :planx do
      name { "PlanX" }
    end
  end
end
