# frozen_string_literal: true

require "faker"

FactoryBot.define do
  factory :planning_application do
    local_authority do
      LocalAuthority.find_by(subdomain: "buckinghamshire") || create(:local_authority)
    end
    description { Faker::Lorem.unique.sentence }
    status { :in_assessment }
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
    user_role { "agent" }
    application_type { :lawfulness_certificate }
    public_comment { "All GDPO compliant" }
    uprn { Faker::Base.numerify("00######") }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    constraints { ["Conservation Area", "Listed Building"] }
    result_flag { "Planning permission / Permission needed" }
    result_heading { Faker::Lorem.unique.sentence }
    result_description { Faker::Lorem.unique.sentence }
    result_override { "Override" }

    proposal_details do
      [
        {
          question: "what are you planning to do?",
          responses: [
            {
              value: "demolish",
              metadata: {
                flags: ["Planning permission / Permission needed"]
              }
            }
          ],
          metadata: {
            notes: "this will be done before rebuilding",
            auto_answered: true,
            policy_refs: [
              {
                url: "http://example.com/planning/policy/1/234/a.html",
                text: "GPDO 32.2342.223"
              }
            ]
          }
        },
        question: "Is this a listed building?",
        responses: [
          {
            value: "No",
            metadata: {
              flags: ["Listed building consent"]
            }
          }
        ]
      ].to_json
    end

    trait :awaiting_determination do
      status                    { :awaiting_determination }
      awaiting_determination_at { Time.zone.now }

      after(:create) do |pa|
        pa.target_date = 35.business_days.from_now
        pa.save!
      end
    end

    trait :not_started do
      status                    { :not_started }
      documents_validated_at    { nil }
    end

    trait :in_assessment do
      status                    { :in_assessment }
      documents_validated_at    { Time.zone.now }

      after(:create) do |pa|
        pa.target_date = Date.current + 7.weeks
        pa.save!
      end
    end

    trait :assessment_in_progress do
      status { :assessment_in_progress }
      assessment_in_progress_at { Time.zone.now }
    end

    trait :awaiting_correction do
      status { :awaiting_correction }
      awaiting_correction_at { Time.zone.now }

      after(:create) do |pa|
        pa.target_date = 35.business_days.from_now
        pa.save!
      end
    end

    trait :determined do
      status        { :determined }
      determined_at { Time.zone.now }
      determination_date { Time.zone.now }
      decision { "granted" }

      after(:create) do |pa|
        pa.target_date = 5.business_days.from_now
        pa.save!
      end
    end

    trait :returned do
      status { :returned }
      returned_at { Time.zone.now }
    end

    trait :withdrawn do
      status { :withdrawn }
      withdrawn_at { Time.zone.now }
    end

    trait :closed do
      status    { :closed }
      closed_at { Time.zone.now }
    end

    trait :invalidated do
      status { :invalidated }
      invalidated_at { Time.zone.now }
    end

    trait :without_result do
      result_flag { "" }
      result_heading { "" }
      result_description { "" }
      result_override { "" }
    end

    trait :with_boundary_geojson do
      boundary_geojson do
        '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}'
      end
    end

    trait :prior_approval do
      result_flag { "Planning permission / Prior approval" }

      proposal_details do
        [
          {
            question: "What do you want to do?",
            responses: [
              {
                value: "Modify or extend"
              }
            ]
          },
          {
            question: "I will add",
            responses: [
              {
                value: "1-2 new storeys",
                metadata: {
                  flags: [
                    "Planning permission / Prior approval"
                  ]
                }
              }
            ]
          },
          {
            question: "The new storeys will be",
            responses: [
              {
                value: "on the principal part of the building only",
                metadata: {
                  flags: [
                    "Planning permission / Prior approval"
                  ]
                }
              }
            ]
          },
          {
            question: "The height of the new roof will be higher than the old roof by",
            responses: [
              {
                value: "7m or less",
                metadata: {
                  flags: [
                    "Planning permission / Prior approval"
                  ]
                }
              }
            ]
          }
        ].to_json
      end
    end

    trait :with_recommendation do
      after(:create) do |planning_application|
        create(:recommendation, planning_application: planning_application)
      end
    end

    factory :not_started_planning_application do
      status { :not_started }

      factory :invalidated_planning_application do
        after(:create) do |p|
          create(
            :additional_document_validation_request,
            :pending,
            planning_application: p
          )

          p.invalidate!
        end

        factory :valid_planning_application do
          after(:create) do |p|
            p.validation_requests.each(&:close!)

            p.start!
          end

          factory :in_assessment_planning_application do
            decision { "granted" }

            after(:create, &:assess!)

            factory :submitted_planning_application do
              after(:create) do |planning_application|
                create(:recommendation, planning_application: planning_application)

                planning_application.submit!
              end

              factory :determined_planning_application do
                after(:create, &:determine!)
              end
            end
          end
        end
      end
    end

    factory :returned_planning_application do
      after(:create) do |application|
        application.return!("this will not do")
      end
    end

    factory :withdrawn_planning_application do
      after(:create) do |application|
        application.withdraw!("no thanks")
      end
    end

    factory :closed_planning_application do
      after(:create, &:close!)
    end
  end
end
