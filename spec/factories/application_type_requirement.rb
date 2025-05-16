# frozen_string_literal: true

FactoryBot.define do
  factory :application_type_requirement, class: "ApplicationTypeRequirement" do
    local_authority_requirement
    application_type
  end
end
