# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_category, class: "LocalAuthority::Category" do
    local_authority
    description { Faker::Lorem.unique.sentence }
  end
end
