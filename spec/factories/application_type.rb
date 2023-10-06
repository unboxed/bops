# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    name { "lawfulness_certificate" }
    assessment_details do
      %w[
        summary_of_work
        site_description
        consultation_summary
        additional_evidence
      ]
    end

    trait :prior_approval do
      name { "prior_approval" }
      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          publicity_summary
          amenity
        ]
      end
    end

    trait :planning_permission do
      name { "planning_permission" }
      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          publicity_summary
        ]
      end
    end

    initialize_with { ApplicationType.find_or_create_by(name:) }
  end
end
