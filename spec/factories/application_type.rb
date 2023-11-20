# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    name { "lawfulness_certificate" }
    steps { %w[validation assessment review] }

    assessment_details do
      %w[
        summary_of_work
        site_description
        consultation_summary
        additional_evidence
        past_applications
      ]
    end

    consistency_checklist do
      %w[
        description_matches_documents
        documents_consistent
        proposal_details_match_documents
        site_map_correct
      ]
    end

    document_tags do
      {
        evidence: [
          "Photograph",
          "Utility Bill",
          "Building Control Certificate",
          "Construction Invoice",
          "Council Tax Document",
          "Tenancy Agreement",
          "Tenancy Invoice",
          "Bank Statement",
          "Statutory Declaration",
          "Other"
        ],
        plans: %w[
          Front
          Rear
          Side
          Roof
          Floor
          Site
          Plan
          Elevation
          Section
          Proposed
          Existing
        ],
        other: [
          "Site Visit",
          "Site Notice",
          "Press Notice"
        ]
      }
    end

    trait :prior_approval do
      name { "prior_approval" }
      steps { %w[validation consultation assessment review] }

      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          publicity_summary
          amenity
          past_applications
        ]
      end

      consistency_checklist do
        %w[
          description_matches_documents
          documents_consistent
          proposal_details_match_documents
          proposal_measurements_match_documents
          site_map_correct
        ]
      end
    end

    trait :planning_permission do
      name { "planning_permission" }
      steps { %w[validation consultation assessment review] }

      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          publicity_summary
          past_applications
        ]
      end

      consistency_checklist do
        %w[
          description_matches_documents
          documents_consistent
          proposal_details_match_documents
          site_map_correct
        ]
      end
    end

    initialize_with { ApplicationType.find_or_create_by(name:) }
  end
end
