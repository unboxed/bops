# frozen_string_literal: true

FactoryBot.define do
  factory :consultee_email, class: "Consultee::Email" do
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    status { "pending" }

    trait :pending do
      sent_at { nil }
      notify_id { nil }
      status { "pending" }
      status_updated_at { nil }
    end

    trait :created do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "created" }
      status_updated_at { 5.minutes.ago }
    end

    trait :sending do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "sending" }
      status_updated_at { 5.minutes.ago }
    end

    trait :delivered do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "delivered" }
      status_updated_at { 5.minutes.ago }
    end

    trait :technical_failure do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "technical-failure" }
      status_updated_at { 5.minutes.ago }
    end

    trait :temporary_failure do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "temporary-failure" }
      status_updated_at { 5.minutes.ago }
    end

    trait :permanent_failure do
      sent_at { 5.minutes.ago }
      notify_id { SecureRandom.uuid }
      status { "permanent-failure" }
      status_updated_at { 5.minutes.ago }
    end
  end
end
