# frozen_string_literal: true

FactoryBot.define do
  factory :site_visit do
    association :created_by, factory: :user
    planning_application

    decision { "Yes" }
    comment { "A comment about the site visit" }
    visited_at { 1.day.ago }

    trait :with_documents do
      before(:create) do |request|
        documents = create_list(
          :document,
          2,
          planning_application: request.planning_application,
          tags: %w[internal.siteVisit]
        )

        request.documents << documents
      end
    end
  end
end
