# frozen_string_literal: true

FactoryBot.define do
  factory :application_type_config, class: "ApplicationType::Config" do
    lawfulness_certificate
    legislation

    trait :lawfulness_certificate do
      name { "lawfulness_certificate" }
      code { "ldc.existing" }
      suffix { "LDCE" }
      steps { %w[validation assessment review] }
      category { "certificate-of-lawfulness" }
      reporting_types { %w[Q26] }

      features {
        {
          assess_against_policies: true
        }
      }

      assessment_details do
        %w[
          summary_of_work
          site_description
          consultation_summary
          additional_evidence
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

      decisions { %w[granted refused] }
      status { "active" }
    end

    trait :ldc_existing do
      lawfulness_certificate

      features {
        {
          "assess_against_policies" => true,
          "informatives" => true,
          "planning_conditions" => false,
          "consultation_steps" => []
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
          "assess_against_policies" => true,
          "informatives" => true,
          "planning_conditions" => false,
          "consultation_steps" => []
        }
      }

      legislation { association :legislation, :ldc_proposed }
    end

    trait :listed do
      name { "other" }
      code { "listed" }
      suffix { "LBC" }
      category { "listed-building" }
      reporting_types { %w[Q23 Q24] }
      steps { %w[validation consultation assessment review] }
      features {
        {
          "assess_against_policies" => true,
          "planning_conditions" => false,
          "permitted_development_rights" => false,
          "site_visits" => false,
          "consultation_steps" => ["neighbour", "consultee", "publicity"]
        }
      }

      assessment_details do
        %w[
          summary_of_work
          site_description
          additional_evidence
          consultation_summary
          neighbour_summary
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
            "streetScene"
          ],
          evidence: [],
          supporting_documents: [
            "designAndAccessStatement",
            "ecologyReport",
            "heritageStatement",
            "joinersReport",
            "joinerySections",
            "planningStatement",
            "internal.siteNotice",
            "internal.siteVisit"
          ]
        }
      end

      decisions { %w[granted refused] }
      status { "active" }
    end

    trait :prior_approval do
      name { "prior_approval" }
      code { "pa.part1.classA" }
      suffix { "PA1A" }
      category { "prior-approval" }
      reporting_types { %w[PA1] }
      features {
        {
          "assess_against_policies" => true,
          "considerations" => true,
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
      decisions { %w[granted not_required refused] }
      status { "active" }
    end

    trait :pa_part1_classA do
      prior_approval
    end

    trait :pa_part_14_class_j do
      prior_approval

      code { "pa.part14.classJ" }
      suffix { "PA14J" }
      category { "prior-approval" }
      reporting_types { %w[PA99] }
      part { 14 }
      section { "J" }

      legislation { association :legislation, :pa_part_14_class_j }
    end

    trait :pa_part_20_class_ab do
      prior_approval

      code { "pa.part20.classAB" }
      suffix { "PA20AB" }
      category { "prior-approval" }
      reporting_types { %w[PA99] }
      part { 20 }
      section { "AB" }

      legislation { association :legislation, :pa_part_20_class_ab }
    end

    trait :pa_part_3_class_ma do
      prior_approval

      code { "pa.part3.classMA" }
      suffix { "PA3MA" }
      category { "prior-approval" }
      reporting_types { %w[PA99] }
      part { 3 }
      section { "MA" }

      legislation { association :legislation, :pa_part_3_class_ma }
    end

    trait :pa_part7_classM do
      prior_approval

      code { "pa.part7.classM" }
      suffix { "PA7M" }
      category { "prior-approval" }
      reporting_types { %w[PA99] }
      part { 7 }
      section { "M" }

      legislation { association :legislation, :pa_part7_classM }
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
          "considerations" => true,
          "informatives" => true,
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

      decisions { %w[granted refused] }
      status { "active" }
    end

    trait :householder do
      planning_permission

      legislation { association :legislation, :tcpa_1990 }
    end

    trait :householder_retrospective do
      planning_permission

      code { "pp.full.householder.retro" }
      suffix { "HAPR" }

      legislation { association :legislation, :tcpa_1990 }
    end

    trait :minor do
      planning_permission

      code { "pp.full.minor" }
      suffix { "MINOR" }
      reporting_types { %w[Q13 Q14 Q15 Q16 Q17 Q18] }

      legislation { association :legislation, :tcpa_1990 }
    end

    trait :major do
      planning_permission

      code { "pp.full.major" }
      suffix { "MAJOR" }
      reporting_types { %w[Q01 Q02 Q03 Q04 Q05 Q06] }

      legislation { association :legislation, :tcpa_1990 }
    end

    trait :listed do
      code { "listed" }
      suffix { "LBC" }
    end

    trait :land_drainage do
      code { "landDrainageConsent" }
      suffix { "LDC" }
    end

    trait :pre_application do
      code { "preApp" }
      suffix { "PRE" }

      features {
        {
          "cil" => false,
          "description_change_requires_validation" => false,
          "eia" => false,
          "legislative_requirements" => false
        }
      }
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

    trait :without_category do
      category { nil }
      reporting_types { [] }
    end

    trait :without_reporting_types do
      reporting_types { [] }
    end

    trait :active do
      status { "active" }
    end

    trait :inactive do
      status { "inactive" }
    end

    initialize_with { ApplicationType::Config.find_or_create_by(code:) }
  end
end
