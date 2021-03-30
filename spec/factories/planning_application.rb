# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    local_authority
    description      { Faker::Lorem.unique.sentence }
    status           { :in_assessment }
    in_assessment_at { Time.zone.now }
    documents_validated_at { Time.zone.today }
    work_status { :proposed }
    agent_first_name { Faker::Name.first_name }
    agent_last_name { Faker::Name.last_name }
    agent_phone { Faker::Base.numerify("+44 7### ######") }
    agent_email { Faker::Internet.email }
    applicant_first_name { Faker::Name.first_name }
    applicant_last_name { Faker::Name.last_name }
    applicant_phone { Faker::Base.numerify("+44 7### ######") }
    applicant_email { Faker::Internet.email }
    application_type { :lawfulness_certificate }
    public_comment { "All GDPO compliant" }
    uprn { Faker::Base.numerify("00######") }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
    constraints { ["Conservation Area", "Listed Building"] }

    proposal_details do
      [
        {
          question: "what are you planning to do?",
          responses: [
            {
              value: "demolish",
            },
          ],
          metadata: {
            notes: "this will be done before rebuilding",
            auto_answered: true,
            policy_refs: [
              {
                url: "http://example.com/planning/policy/1/234/a.html",
                text: "GPDO 32.2342.223",
              },
            ],
          },
        },
      ].to_json
    end
  end

  trait :awaiting_determination do
    status                    { :awaiting_determination }
    awaiting_determination_at { Time.zone.now }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :not_started do
    status                    { :not_started }
    documents_validated_at    { nil }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :awaiting_correction do
    status { :awaiting_correction }
    awaiting_correction_at { Time.zone.now }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :determined do
    status        { :determined }
    determined_at { Time.zone.now }

    after(:create) do |pa|
      pa.target_date = Date.current + 1.week
      pa.save!
    end
  end

  trait :invalidated do
    status { :invalidated }
    invalidated_at { Time.zone.now }
  end
end
