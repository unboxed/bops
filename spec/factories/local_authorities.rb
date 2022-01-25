# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    name { Faker::Name.name }
    subdomain { Faker::Internet.unique.domain_word }
    signatory_name { Faker::FunnyName.two_word_name }
    signatory_job_title { "Director" }
    enquiries_paragraph { Faker::Lorem.unique.sentence }
    email_address { Faker::Internet.email }

    trait :default do
      name { "Default Authority" }
      subdomain { "default" }
    end

    trait :lambeth do
      name { "Lambeth Council Authority" }
      subdomain { "lambeth_authority" }
      signatory_name { "Christina Thompson" }
      signatory_job_title { "Director of Finance & Property" }
      enquiries_paragraph { "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@lambeth.gov.uk" }
    end

    trait :southwark do
      name { "Southwark Council Authority" }
      subdomain { "southwark_authority" }
      signatory_name { "Stephen Platts" }
      signatory_job_title { "Director of Planning and Growth" }
      enquiries_paragraph { "Planning, London Borough of Southwark, PO Box 734, Winchester SO23 5DG" }
      email_address { "planning@southwark.gov.uk" }
    end
  end
end
