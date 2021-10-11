# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority do
    name { Faker::Name.name }
    subdomain { Faker::Internet.unique.domain_word }
    signatory_name { Faker::FunnyName.two_word_name }
    signatory_job_title { "Director" }
    enquiries_paragraph { Faker::Lorem.unique.sentence }
    email_address { Faker::Internet.email }
  end
end
