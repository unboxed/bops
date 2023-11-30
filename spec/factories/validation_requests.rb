# frozen_string_literal: true

FactoryBot.define do
  factory :validation_request do
    planning_application
    for_other_change_validation_request

    trait :for_other_change_validation_request do
      association :requestable, factory: :other_change_validation_request
    end

    trait :for_additional_document_validation_request do
      association :requestable, factory: :additional_document_validation_request
    end

    trait :for_red_line_boundary_change_validation_request do
      association :requestable, factory: :red_line_boundary_change_validation_request
    end

    trait :for_replacement_document_validation_request do
      association :requestable, factory: :replacement_document_validation_request
    end

    trait :for_description_change_validation_request do
      association :requestable, factory: :description_change_validation_request
    end
  end
end
