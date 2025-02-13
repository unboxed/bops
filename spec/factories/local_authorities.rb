# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    council_code { "BUC" }
    subdomain { "buckinghamshire" }
    short_name { "Buckinghamshire" }
    council_name { "Buckinghamshire Council" }
    applicants_url { "https://planningapplications.buckinghamshire.gov.uk" }
    signatory_name { Faker::FunnyName.two_word_name }
    signatory_job_title { "Director" }
    enquiries_paragraph { Faker::Lorem.unique.sentence }
    email_address { Faker::Internet.email }
    feedback_email { "feedback_email@buckinghamshire.gov.uk" }
    email_reply_to_id { "4896bb50-4f4c-4b4d-ad67-2caddddde125" }
    active { true }
    application_type_overrides do
      [
        {
          code: :preApp,
          determination_period_days: 30
        }
      ]
    end

    trait :default do
      council_code { "PlanX" }
      subdomain { "planx" }
      short_name { "PlanX" }
      council_name { "PlanX Council" }
      applicants_url { "https://planx.bops-applicants.services" }
      public_register_base_url { "https://planningregister.org/planx" }
      signatory_name { Faker::FunnyName.two_word_name }
      signatory_job_title { "Director" }
      enquiries_paragraph { Faker::Lorem.unique.sentence }
      email_address { "planning@planx.uk" }
      feedback_email { "feedback_email@planx.uk" }
      email_reply_to_id { "4485df6f-a728-41ed-bc46-cdb2fc6789aa" }
    end

    trait :lambeth do
      council_code { "LBH" }
      subdomain { "lambeth" }
      short_name { "Lambeth" }
      council_name { "Lambeth Council" }
      applicants_url { "https://planningapplications.lambeth.gov.uk" }
      signatory_name { "Christina Thompson" }
      signatory_job_title { "Director of Finance & Property" }
      enquiries_paragraph { "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@lambeth.gov.uk" }
      feedback_email { "feedback_email@lambeth.gov.uk" }
      email_reply_to_id { "5fe1d483-9bbe-4b56-8e71-8ce193fef723" }
    end

    trait :southwark do
      council_code { "SWK" }
      subdomain { "southwark" }
      short_name { "Southwark" }
      council_name { "Southwark Council" }
      applicants_url { "https://planningapplications.southwark.gov.uk" }
      signatory_name { "Stephen Platts" }
      signatory_job_title { "Director of Planning and Growth" }
      enquiries_paragraph { "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@southwark.gov.uk" }
      feedback_email { "feedback_email@southwark.gov.uk" }
      email_reply_to_id { "f755c178-b01a-4323-a756-d669e9350c33" }
    end

    trait :barnet do
      council_code { "BAR" }
      subdomain { "barnet" }
      short_name { "Barnet" }
      council_name { "Barnet Council" }
      applicants_url { "https://planningapplications.barnet.gov.uk" }
      signatory_name { Faker::FunnyName.two_word_name }
      signatory_job_title { "Director of Planning and Growth" }
      enquiries_paragraph { Faker::Lorem.unique.sentence }
      email_address { Faker::Internet.email }
      feedback_email { nil }
      email_reply_to_id { nil }
    end

    trait :unconfigured do
      press_notice_email { nil }
      notify_api_key { nil }
      letter_template_id { nil }
      reviewer_group_email { nil }
      active { false }
    end

    trait :with_api_user do
      after(:create) do |local_authority|
        local_authority.api_users.find_or_create_by!(name: local_authority.subdomain)
      end
    end

    trait :planning_history do
      planning_history_enabled { true }
    end
  end
end
