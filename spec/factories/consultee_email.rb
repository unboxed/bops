# frozen_string_literal: true

FactoryBot.define do
  factory :consultee_email, class: "Consultee::Email" do
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    status { "pending" }
  end
end
