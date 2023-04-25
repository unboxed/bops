# frozen_string_literal: true

FactoryBot.define do
  factory :evidence_group do
    immunity_detail
    start_date { 6.years.ago }
    end_date { 4.years.ago }
    tag { "utility_bill" }
    applicant_comment { "This is my proof" }

    trait :with_document do
      after :create do |evidence_group|
        create(:document, :evidence, evidence_group:)
      end
    end
  end
end
