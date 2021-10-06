# frozen_string_literal: true

FactoryBot.define do
  factory :replacement_document_validation_request do
    planning_application
    user
    old_document factory: :document
    new_document factory: :document
    state { "open" }
  end
end
