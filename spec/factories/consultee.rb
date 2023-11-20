# frozen_string_literal: true

FactoryBot.define do
  factory :consultee do
    name { Faker::Name.name }
    email_address { Faker::Internet.email }
    status { "not_consulted" }
    origin { :internal }

    trait :internal do
      origin { :internal }
    end

    trait :external do
      origin { :external }
    end

    trait :created do
      status { "sending" }
      email_sent_at { nil }
      email_delivered_at { nil }
      last_email_sent_at { nil }
      last_email_delivered_at { nil }
    end

    trait :sending do
      status { "sending" }
      email_sent_at { 5.minutes.ago }
      email_delivered_at { nil }
      last_email_sent_at { 5.minutes.ago }
      last_email_delivered_at { nil }
    end

    trait :resending do
      status { "sending" }
      email_sent_at { 7.days.ago }
      email_delivered_at { 7.days.ago }
      last_email_sent_at { 5.minutes.ago }
      last_email_delivered_at { 7.days.ago }
    end

    trait :resend_failed do
      status { "failed" }
      email_sent_at { 7.days.ago }
      email_delivered_at { 7.days.ago }
      last_email_sent_at { 5.minutes.ago }
      last_email_delivered_at { 7.days.ago }
    end

    trait :consulted do
      status { "awaiting_response" }
      email_sent_at { 7.days.ago }
      email_delivered_at { 7.days.ago }
      last_email_sent_at { 7.days.ago }
      last_email_delivered_at { 7.days.ago }
      expires_at { 14.days.from_now.end_of_day }
    end

    trait :with_response do
      responses { build_list(:consultee_response, 1) }
    end
  end
end
