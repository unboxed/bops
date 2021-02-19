# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    site
    local_authority
    description      { Faker::Lorem.unique.sentence }
    status           { :in_assessment }
    in_assessment_at { Time.zone.now }
    ward             { Faker::Address.city }
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
    questions do
      {
        flow: [
          {
            id: "-LsXty7cOZycK0rqv8B2",
            text: "The property is",
            val: "property.buildingType",
            choice: {
              id: "-LsXty7cOZycK0rqv8B7",
              idx: 3,
              recorded_at: "2020-05-14T05:18:17.540Z",
              auto: true,
            },
          },
        ],
      }.to_json
    end
    constraints do
      {
        conservation_area: true,
        protected_trees: false,
      }.to_json
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
