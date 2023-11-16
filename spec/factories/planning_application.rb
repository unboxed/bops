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
    validated_at { Time.zone.today }
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
    public_comment { "All GDPO compliant" }
    uprn { Faker::Base.numerify("00######") }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
    lonlat { "POINT(#{Faker::Address.longitude} #{Faker::Address.latitude})" }
    result_flag { "Planning permission / Permission needed" }
    result_heading { Faker::Lorem.unique.sentence }
    result_description { Faker::Lorem.unique.sentence }
    result_override { "Override" }
    application_type { ApplicationType.first }

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
        {
          question: "Enter the address of the first adjoining property",
          responses: [
            {
              value: "London, 80 Underhill Road , , , , SE22 0QU"
            }
          ]
        },
        {
          question: "Enter the address of the second adjoining property",
          responses: [
            {
              value: "London, 78 Underhill Road, , , , SE22 0QU"
            }
          ]
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
      status { :awaiting_determination }
      awaiting_determination_at { Time.zone.now }
      decision { "granted" }

      after(:create) do |pa|
        pa.target_date = 35.business_days.from_now
        pa.save!
      end
    end

    trait :not_started do
      status { :not_started }
      validated_at { nil }
    end

    trait :in_assessment do
      status { :in_assessment }
      validated_at { Time.zone.now }

      after(:create) do |pa|
        pa.target_date = Date.current + 7.weeks
        pa.save!
      end
    end

    trait :assessment_in_progress do
      status { :assessment_in_progress }
      assessment_in_progress_at { Time.zone.now }
    end

    trait :to_be_reviewed do
      status { :to_be_reviewed }
      to_be_reviewed_at { Time.zone.now }

      after(:create) do |pa|
        pa.target_date = 35.business_days.from_now
        pa.save!
      end
    end

    trait :determined do
      status { :determined }
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
      status { :closed }
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
            question: "Exactly how far will the new addition extend beyond the back wall of the original house?",
            responses: [
              {
                value: "4.5"
              }
            ],
            metadata: {
              policy_refs: [
                {
                  text: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Schedule 2, Part 1, Class A"
                }
              ],
              section_name: "Rear and side extensions to houses"
            }
          },
          {
            question: "Exactly how high are the eaves of the extension?",
            responses: [
              {
                value: "2.5"
              }
            ],
            metadata: {
              policy_ref: [
                {
                  text: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Schedule 2, Part 1, Class APermitted Development Rights for Householders Technical Guidance (PDF, 500KB)"
                }
              ],
              section_name: "Rear and side extensions to houses"
            }
          },
          {
            question: "What is the exact height of the extension?",
            responses: [
              {
                value: "3"
              }
            ],
            metadata: {
              policy_refs: [
                {
                  text: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Schedule 2, Part 1, Class A"
                }
              ],
              section_name: "Rear and side extensions to houses"
            }
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

      application_type { ApplicationType.find_by(name: :prior_approval) }

      after(:create) do |planning_application|
        create(:proposal_measurement, planning_application:)
      end
    end

    trait :planning_permission do
      application_type { ApplicationType.find_by(name: :planning_permission) }
    end

    trait :with_consultees do
      after(:create) do |planning_application|
        consultation = planning_application.consultation || planning_application.create_consultation!
        create_list(:consultee, 3, consultation:)
      end
    end

    trait :with_condition_set do
      after(:create) do |planning_application|
        planning_application.condition_set || planning_application.create_condition_set!
      end
    end

    trait :with_recommendation do
      after(:create) do |planning_application|
        create(:recommendation, planning_application:)
      end
    end

    trait :with_feedback do
      feedback do
        {
          "result" => "feedback about the result",
          "find_property" => "feedback about the property",
          "planning_constraints" => "feedback about the constraints"
        }
      end
    end

    trait :with_constraints do
      after(:create) do |planning_application|
        constraint1 = create(:constraint)
        constraint2 = create(:constraint, :listed)

        planning_application.planning_application_constraints.find_or_create_by(constraint: constraint1, identified: true, identified_by: planning_application.api_user.name).save!
        planning_application.planning_application_constraints.find_or_create_by(constraint: constraint2, identified: true, identified_by: planning_application.api_user.name).save!
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
                create(:recommendation, planning_application:)

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

    trait :from_planx do
      audit_log { file_fixture("planx_params.json").read }
    end

    trait :from_planx_immunity do
      audit_log { file_fixture("planx_params_immunity.json").read }

      proposal_details do
        [
          {
            responses: [{
              value: "Install a security alarm",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check"
            },
            question: "List the changes involved in the project"
          },
          {
            responses: [{
              value: "Alteration",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              auto_answered: true
            },
            question: "What type of changes were they?"
          },
          {
            responses: [{
              value: "Yes",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "Were the works carried out more than 4 years ago?"
          },
          {
            responses: [{
              value: "Yes",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "Have the works been completed?"
          },
          {
            responses: [{
              value: "that it was certified"
            }],
            metadata: {
              section_name: "certificate-of-lawfulness-documents-immunity"
            },
            question: "What do these building control certificates show?"
          },
          {
            responses: [{
              value: "2016-02-01"
            }],
            metadata: {
              section_name: "certificate-of-lawfulness-documents-immunity"
            },
            question: "When was this building control certificate issued?"
          },
          {
            responses: [{
              value: "2013-03-02"
            }],
            metadata: {
              section_name: "certificate-of-lawfulness-documents-immunity"
            },
            question: "What date do these utility bills start from?"
          },
          {
            responses: [{
              value: "2019-04-01"
            }],
            metadata: {
              section_name: "certificate-of-lawfulness-documents-immunity"
            },
            question: "What date do these utility bills run until?"
          },
          {
            responses: [{
              value: "That i was paying water bills"
            }],
            metadata: {
              section_name: "certificate-of-lawfulness-documents-immunity"
            },
            question: "What do these utility bills show?"
          },
          {
            responses: [{
              value: "2015-02-01",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "When were the works completed?"
          },
          {
            responses: [{
              value: "No",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Secretary of State for Communities and Local Government and another v Welwyn Hatfield Borough Council and Bonsall / Jackson v Secretary of State for Communities and Local Government"
              }]
            },
            question: "Has anyone ever attempted to conceal the changes?"
          },
          {
            responses: [{
              value: "No",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Enforcement action is defined in the Town and Country Planning Act 1990 Section 171A.\n'Lawful development' is defined in the Town and Country Planning Act 1990 Section 191."
              }]
            },
            question: "Has enforcement action been taken about these changes?"
          }
        ].to_json
      end
    end

    trait :from_planx_prior_approval do
      audit_log { file_fixture("planx_params_prior_approval.json").read }
    end

    trait :from_planx_prior_approval_not_accepted do
      audit_log { file_fixture("planx_params_prior_approval_not_accepted.json").read }
    end

    trait :with_immunity do
      proposal_details do
        [
          {
            responses: [{
              value: "Install a security alarm",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check"
            },
            question: "List the changes involved in the project"
          },
          {
            responses: [{
              value: "Alteration",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              auto_answered: true
            },
            question: "What type of changes were they?"
          },
          {
            responses: [{
              value: "Yes",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "Were the works carried out more than 4 years ago?"
          },
          {
            responses: [{
              value: "Yes",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "Have the works been completed?"
          },
          {
            responses: [{
              value: "2015-02-01",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Town and Country Planning Act 1990 Section 171B"
              }]
            },
            question: "When were the works completed?"
          },
          {
            responses: [{
              value: "No",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Secretary of State for Communities and Local Government and another v Welwyn Hatfield Borough Council and Bonsall / Jackson v Secretary of State for Communities and Local Government"
              }]
            },
            question: "Has anyone ever attempted to conceal the changes?"
          },
          {
            responses: [{
              value: "No",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }],
            metadata: {
              section_name: "immunity-check",
              policy_refs: [{
                text: "Enforcement action is defined in the Town and Country Planning Act 1990 Section 171A.\n'Lawful development' is defined in the Town and Country Planning Act 1990 Section 191."
              }]
            },
            question: "Has enforcement action been taken about these changes?"
          }
        ].to_json
      end

      after(:create) do |planning_application|
        create(:immunity_detail, planning_application:)
      end
    end
  end
end
