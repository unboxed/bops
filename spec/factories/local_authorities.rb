# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    council_code { "BUC" }
    subdomain { "buckinghamshire" }
    signatory_name { Faker::FunnyName.two_word_name }
    signatory_job_title { "Director" }
    enquiries_paragraph { Faker::Lorem.unique.sentence }
    email_address { Faker::Internet.email }
    feedback_email { "feedback_email@buckinghamshire.gov.uk" }

    trait :default do
      council_code { "PlanX" }
      subdomain { "planx" }
      signatory_name { Faker::FunnyName.two_word_name }
      signatory_job_title { "Director" }
      enquiries_paragraph { Faker::Lorem.unique.sentence }
      email_address { "planning@planx.uk" }
      feedback_email { "feedback_email@planx.uk" }
    end

    trait :lambeth do
      council_code { "LBH" }
      subdomain { "lambeth" }
      signatory_name { "Christina Thompson" }
      signatory_job_title { "Director of Finance & Property" }
      enquiries_paragraph { "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@lambeth.gov.uk" }
      feedback_email { "feedback_email@lambeth.gov.uk" }
    end

    trait :southwark do
      council_code { "SWK" }
      subdomain { "southwark" }
      signatory_name { "Stephen Platts" }
      signatory_job_title { "Director of Planning and Growth" }
      enquiries_paragraph { "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@southwark.gov.uk" }
      feedback_email { "feedback_email@southwark.gov.uk" }
    end
  end
end
