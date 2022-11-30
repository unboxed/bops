# frozen_string_literal: true

FactoryBot.define do
  factory :additional_document_validation_request do
    planning_application { create(:planning_application, :invalidated) }
    user
    state { "open" }
    document_request_type { "Floor plan" }
    document_request_reason { "Missing floor plan" }
    post_validation { false }

    trait :with_documents do
      before(:create) do |request|
        document = create(
          :document,
          planning_application: request.planning_application
        )

        request.documents << document
      end
    end

    trait :pending do
      planning_application { create(:planning_application, :not_started) }

      state { "pending" }
    end

    trait :open do
      state { "open" }
    end

    trait :closed do
      state { "closed" }
    end

    trait :cancelled do
      state { "cancelled" }
      cancel_reason { "Made by mistake!" }
      cancelled_at { Time.current }
    end

    trait :post_validation do
      post_validation { true }
    end
  end
end
