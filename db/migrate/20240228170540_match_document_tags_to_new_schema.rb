# frozen_string_literal: true

class MatchDocumentTagsToNewSchema < ActiveRecord::Migration[7.1]
  def up
    ApplicationType.find_each do |type|
      tags = if type.name == "lawfulness_certificate"
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
      else
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

      type.update!(document_tags: tags)
    end
  end

  def down
    ApplicationType.find_each do |type|
      tags = if type.name == "lawfulness_certificate"
        {
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
          supporting_documents: []
        }
      else
        {
          evidence: [
            "Discounts"
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
          supporting_documents: [
            "Site Visit",
            "Site Notice",
            "Press Notice",
            "Design and Access Statement",
            "Planning Statement",
            "Viability Appraisal",
            "Heritage Statement",
            "Agricultural, Forestry or Occupational Worker Dwelling Justification",
            "Arboricultural Assessment",
            "Structural Survey/report",
            "Air Quality Assessment",
            "Basement Impact Assessment",
            "Biodiversity Net Gain (from April)",
            "Contaminated Land Assessment",
            "Daylight and Sunlight Assessment",
            "Flood Risk Assessment/Drainage and SuDs Report",
            "Landscape and Visual Impact Assessment",
            "Noise Impact Assessment",
            "Open Space Assessment",
            "Sustainability and Energy Statement",
            "Transport Statement",
            "NDSS Compliance Statement",
            "Ventilation/Extraction Statement",
            "Community Infrastructure Levy (CIL) form",
            "Gypsy and Traveller Statement",
            "HMO statement",
            "Specialist Accommodation Statement",
            "Student Accommodation Statement",
            "Other Supporting Document"
          ]
        }
      end

      type.update!(document_tags: tags)
    end
  end
end
