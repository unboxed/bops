# frozen_string_literal: true

FactoryBot.define do
  factory :submission do
    association :local_authority
    request_headers { {"Content-Type" => "application/json"} }
    request_body {
      {
        applicationRef: "10027719",
        applicationVersion: 1,
        applicationState: "Submitted",
        sentDateTime: "2023-06-19T08:45:59.9722472Z",
        documentLinks: [
          {
            documentName: "PT-10027719.zip",
            documentLink: "https://example.com/PT-10027719.zip",
            expiryDateTime: "2023-07-19T08:45:59.975412Z",
            documentType: "application/x-zip-compressed"
          }
        ],
        updated: false
      }
    }
    external_uuid { SecureRandom.uuid_v7 }

    trait :completed do
      after(:create) do |submission|
        submission.start!
        submission.complete!
      end
    end

    trait :failed do
      after(:create) do |submission|
        submission.start!
        submission.fail!
      end
    end
  end
end
