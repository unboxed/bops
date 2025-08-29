# frozen_string_literal: true

FactoryBot.define do
  factory :api_user do
    local_authority do
      LocalAuthority.find_by(subdomain: "planx") || create(:local_authority, subdomain: "planx")
    end
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
      permissions {
        ["planning_application:read", "comment:read",
          "planning_application:write", "comment:write"]
      }
    end

    trait :planx do
      name { "PlanX" }
      permissions { ["planning_application:write"] }
    end

    trait :comment_ro do
      name { "DPR" }
      permissions { ["comment:read"] }
    end

    trait :comment_rw do
      name { "DPR" }
      permissions { ["comment:read", "comment:write"] }
    end

    trait :validation_requests_ro do
      permissions { ["validation_request:read"] }
    end

    trait :validation_requests_rw do
      permissions { ["validation_request:read", "validation_request:write"] }
    end
  end
end
