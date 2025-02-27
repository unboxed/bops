# frozen_string_literal: true

FactoryBot.define do
  factory :local_authority_application_type, class: "LocalAuthority::ApplicationType" do
    local_authority
    application_type

    trait :pre_app do
      association :application_type, :pre_application
      determination_period_days { 30 }
    end
  end
end
