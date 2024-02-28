# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    lawfulness_certificate

    trait :lawfulness_certificate do
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
    end

    trait :prior_approval do
      name { "prior_approval" }
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
    end

    trait :planning_permission do
      name { "planning_permission" }
      steps { %w[validation consultation assessment review] }
      features { {"planning_conditions" => true, "permitted_development_rights" => false} }

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
    end

    initialize_with { ApplicationType.find_or_create_by(name:) }
  end
end
