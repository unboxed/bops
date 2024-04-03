# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    lawfulness_certificate
    legislation

    trait :lawfulness_certificate do
      name { "lawfulness_certificate" }
      code { "ldc.existing" }
      suffix { "LDCE" }
      steps { %w[validation assessment review] }
      category { "certificate-of-lawfulness" }
      reporting_types { %w[Q26] }

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
          plans: [
            "elevations.existing",
            "elevations.proposed",
            "floorPlan.existing",
            "floorPlan.proposed",
            "internalElevations",
            "internalSections",
            "locationPlan",
            "otherDrawing",
            "roofPlan.existing",
            "roofPlan.proposed",
            "sections.existing",
            "sections.proposed",
            "sitePlan.existing",
            "sitePlan.proposed",
            "sketchPlan",
            "streetScene",
            "unitPlan.existing",
            "unitPlan.proposed",
            "usePlan.existing",
            "usePlan.proposed"
          ],
          evidence: [
            "bankStatement",
            "buildingControlCertificate",
            "constructionInvoice",
            "councilTaxBill",
            "otherEvidence",
            "photographs.existing",
            "photographs.proposed",
            "statutoryDeclaration",
            "tenancyAgreement",
            "tenancyInvoice",
            "utilitiesStatement",
            "utilityBill"
          ],
          supporting_documents: []
        }
      end

      status { "active" }
    end

    trait :ldc_existing do
      lawfulness_certificate

      features {
        {
          consultation_steps: []
        }
      }

      legislation { association :legislation, :ldc_existing }
    end

    trait :ldc_proposed do
      lawfulness_certificate

      code { "ldc.proposed" }
      suffix { "LDCP" }

      features {
        {
          consultation_steps: []
        }
      }

      legislation { association :legislation, :ldc_proposed }
    end

    trait :prior_approval do
      name { "prior_approval" }
      code { "pa.part1.classA" }
      suffix { "PA" }
      category { "prior-approval" }
      reporting_types { %w[PA1] }
      features {
        {
          "site_visits" => true,
          "consultation_steps" => ["neighbour", "publicity", "consultee"]
        }
      }
      steps { %w[validation consultation assessment review] }

      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          neighbour_summary
          amenity
          past_applications
          check_publicity
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

      document_tags do
        {
          plans: [
            "elevations.existing",
            "elevations.proposed",
            "floorPlan.existing",
            "floorPlan.proposed",
            "internalElevations",
            "internalSections",
            "locationPlan",
            "otherDrawing",
            "roofPlan.existing",
            "roofPlan.proposed",
            "sections.existing",
            "sections.proposed",
            "sitePlan.existing",
            "sitePlan.proposed",
            "sketchPlan",
            "streetScene",
            "unitPlan.existing",
            "unitPlan.proposed",
            "usePlan.existing",
            "usePlan.proposed"
          ],
          evidence: [
            "photographs.existing"
          ],
          supporting_documents: [
            "affordableHousingStatement",
            "arboriculturistReport",
            "basementImpactStatement",
            "bioaerosolAssessment",
            "bioaerosolAssessment",
            "birdstrikeRiskManagementPlan",
            "boreholeOrTrialPitAnalysis",
            "conditionSurvey",
            "contaminationReport",
            "crimePreventionStrategy",
            "designAndAccessStatement",
            "disabilityExemptionEvidence",
            "ecologyReport",
            "emissionsMitigationAndMonitoringScheme",
            "energyStatement",
            "environmentalImpactAssessment",
            "fireSafetyReport",
            "floodRiskAssessment",
            "foulDrainageAssessment",
            "geodiversityAssessment",
            "heritageStatement",
            "hydrologicalAssessment",
            "hydrologyReport",
            "internal.pressNotice",
            "internal.siteNotice",
            "internal.siteVisit",
            "joinersReport",
            "joinerySections",
            "landContaminationAssessment",
            "landscapeAndVisualImpactAssessment",
            "landscapeStrategy",
            "lightingAssessment",
            "litterVerminAndBirdControlDetails",
            "mineralsAndWasteAssessment",
            "newDwellingsSchedule",
            "noiseAssessment",
            "openSpaceAssessment",
            "otherDocument",
            "parkingPlan",
            "planningStatement",
            "statementOfCommunityInvolvement",
            "storageTreatmentAndWasteDisposalDetails",
            "subsidenceReport",
            "sunlightAndDaylightReport",
            "sustainabilityStatement",
            "technicalEvidence",
            "townCentreImpactAssessment",
            "townCentreSequentialAssessment",
            "transportAssessment",
            "travelPlan",
            "treeCanopyCalculator",
            "treeConditionReport",
            "treesReport",
            "ventilationStatement",
            "viabilityAppraisal",
            "visualisations",
            "wasteAndRecyclingStrategy",
            "waterEnvironmentAssessment"
          ]
        }
      end

      legislation { association :legislation, :pa_part1_classA }
      status { "active" }
    end

    trait :pa_part_14_class_j do
      prior_approval

      code { "pa.part14.classJ" }
      suffix { "PA14J" }
      category { "prior-approval" }
      reporting_types { [] }
      part { 14 }
      section { "J" }
    end

    trait :planning_permission do
      name { "planning_permission" }
      code { "pp.full.householder" }
      suffix { "HAPP" }
      category { "householder" }
      reporting_types { %w[Q21] }
      steps { %w[validation consultation assessment review] }
      features {
        {
          "planning_conditions" => true,
          "permitted_development_rights" => false,
          "site_visits" => true,
          "consultation_steps" => ["neighbour", "publicity", "consultee"]
        }
      }

      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          neighbour_summary
          past_applications
          check_publicity
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
          plans: [
            "elevations.existing",
            "elevations.proposed",
            "floorPlan.existing",
            "floorPlan.proposed",
            "internalElevations",
            "internalSections",
            "locationPlan",
            "otherDrawing",
            "roofPlan.existing",
            "roofPlan.proposed",
            "sections.existing",
            "sections.proposed",
            "sitePlan.existing",
            "sitePlan.proposed",
            "sketchPlan",
            "streetScene",
            "unitPlan.existing",
            "unitPlan.proposed",
            "usePlan.existing",
            "usePlan.proposed"
          ],
          evidence: [
            "photographs.existing"
          ],
          supporting_documents: [
            "affordableHousingStatement",
            "arboriculturistReport",
            "basementImpactStatement",
            "bioaerosolAssessment",
            "bioaerosolAssessment",
            "birdstrikeRiskManagementPlan",
            "boreholeOrTrialPitAnalysis",
            "conditionSurvey",
            "contaminationReport",
            "crimePreventionStrategy",
            "designAndAccessStatement",
            "disabilityExemptionEvidence",
            "ecologyReport",
            "emissionsMitigationAndMonitoringScheme",
            "energyStatement",
            "environmentalImpactAssessment",
            "fireSafetyReport",
            "floodRiskAssessment",
            "foulDrainageAssessment",
            "geodiversityAssessment",
            "heritageStatement",
            "hydrologicalAssessment",
            "hydrologyReport",
            "internal.pressNotice",
            "internal.siteNotice",
            "internal.siteVisit",
            "joinersReport",
            "joinerySections",
            "landContaminationAssessment",
            "landscapeAndVisualImpactAssessment",
            "landscapeStrategy",
            "lightingAssessment",
            "litterVerminAndBirdControlDetails",
            "mineralsAndWasteAssessment",
            "newDwellingsSchedule",
            "noiseAssessment",
            "openSpaceAssessment",
            "otherDocument",
            "parkingPlan",
            "planningStatement",
            "statementOfCommunityInvolvement",
            "storageTreatmentAndWasteDisposalDetails",
            "subsidenceReport",
            "sunlightAndDaylightReport",
            "sustainabilityStatement",
            "technicalEvidence",
            "townCentreImpactAssessment",
            "townCentreSequentialAssessment",
            "transportAssessment",
            "travelPlan",
            "treeCanopyCalculator",
            "treeConditionReport",
            "treesReport",
            "ventilationStatement",
            "viabilityAppraisal",
            "visualisations",
            "wasteAndRecyclingStrategy",
            "waterEnvironmentAssessment"
          ]
        }
      end

      status { "active" }
    end

    trait :householder do
      planning_permission

      legislation { association :legislation, :pp_full_householder }
    end

    trait :householder_retrospective do
      planning_permission

      code { "pp.full.householder.retro" }
      suffix { "HRET" }

      legislation { association :legislation, :pp_full_householder_retro }
    end

    trait :without_consultation do
      features {
        {
          consultation_steps: []
        }
      }
    end

    trait :configured do
      configured { true }
    end

    trait :without_legislation do
      legislation { nil }
    end

    trait :active do
      status { "active" }
    end

    trait :inactive do
      status { "inactive" }
    end

    initialize_with { ApplicationType.find_or_create_by(code:) }
  end
end
