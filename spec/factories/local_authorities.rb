# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    subdomain { "buckinghamshire" }
    signatory_name { Faker::FunnyName.two_word_name }
    signatory_job_title { "Director" }
    enquiries_paragraph { Faker::Lorem.unique.sentence }
    email_address { Faker::Internet.email }

    trait :default do
      subdomain { "ripa" }
    end

    trait :lambeth do
      subdomain { "lambeth" }
      signatory_name { "Christina Thompson" }
      signatory_job_title { "Director of Finance & Property" }
      enquiries_paragraph { "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@lambeth.gov.uk" }
      feedback_email { "feedback_email@lambeth.gov.uk" }
    end

    trait :southwark do
      subdomain { "southwark" }
      signatory_name { "Stephen Platts" }
      signatory_job_title { "Director of Planning and Growth" }
      enquiries_paragraph { "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@southwark.gov.uk" }
      feedback_email { "feedback_email@southwark.gov.uk" }
    end
  end
end
