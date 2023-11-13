# frozen_string_literal: true

FactoryBot.define do
  factory :consultee do
    name { Faker::Name.name }
    origin { :internal }

    trait :internal do
      origin { :internal }
    end

    trait :external do
      origin { :external }
    end

    trait :consulted do
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
