# frozen_string_literal: true

module BopsApi
  module Application
    class DocumentsService
      MAPPING = {
        # v0.2.x
        "applicant.disability.evidence" => ["Discounts"],
        "property.drawing.elevation" => ["Elevation", "Existing"],
        "property.drawing.floorPlan" => ["Floor", "Existing"],
        "property.drawing.roofPlan" => ["Roof", "Existing"],
        "property.drawing.section" => ["Section", "Existing"],
        "property.drawing.sitePlan" => ["Site", "Existing"],
        "property.drawing.usePlan" => ["Plan", "Existing"],
        "property.photograph" => ["Photograph"],
        "proposal.drawing.elevation" => ["Elevation", "Proposed"],
        "proposal.drawing.floorPlan" => ["Floor", "Proposed"],
        "proposal.drawing.locationPlan" => ["Other Supporting Document", "Proposed"],
        "proposal.drawing.other" => ["Other Supporting Document", "Proposed"],
        "proposal.drawing.roofPlan" => ["Roof", "Proposed"],
        "proposal.drawing.section" => ["Section", "Proposed"],
        "proposal.drawing.sitePlan" => ["Site", "Proposed"],
        "proposal.drawing.unitPlan" => ["Plan", "Proposed"],
        "proposal.drawing.usePlan" => ["Plan", "Proposed"],
        "proposal.document.bankStatement" => ["Bank Statement"],
        "proposal.document.buildingControl.certificate" => ["Building Control Certificate"],
        "proposal.document.construction.invoice" => ["Construction Invoice"],
        "proposal.document.contamination" => ["Contaminated Land Assessment"],
        "proposal.document.councilTaxBill" => ["Council Tax Document"],
        "proposal.document.declaration" => ["Statutory Declaration"],
        "proposal.document.designAndAccess" => ["Design and Access Statement"],
        "proposal.document.eia" => ["Environment Impact Assessment"],
        "proposal.document.fireSafety" => ["Other Supporting Document"],
        "proposal.document.floodRisk" => ["Flood Risk Assessment/Drainage and SuDs Report"],
        "proposal.document.heritageStatement" => ["Heritage Statement"],
        "proposal.document.noise" => ["Noise Impact Assessment"],
        "proposal.document.other" => ["Other Supporting Document"],
        "proposal.document.other.evidence" => ["Other"],
        "proposal.document.sunAndDaylight" => ["Daylight and Sunlight Assessment"],
        "proposal.document.tenancyAgreement" => ["Tenancy Agreement"],
        "proposal.document.tenancyInvoice" => ["Tenancy Invoice"],
        "proposal.document.transport" => ["Transport Statement"],
        "proposal.document.utility.bill" => ["Utility Bill"],
        "proposal.photograph" => ["Photograph"],
        "proposal.photograph.evidence" => ["Photograph"],
        "proposal.visualisation" => ["Other Supporting Document"],
        # v0.3.x
        "affordableHousingStatement" => ["Other Supporting Document"],
        "arboriculturistReport" => ["Arboricultural Assessment"],
        "bankStatement" => ["Bank Statement"],
        "basementImpactStatement" => ["Basement Impact Assessment"],
        "bioaerosolAssessment" => ["Other Supporting Document"],
        "birdstrikeRiskManagementPlan" => ["Other Supporting Document"],
        "boreholeOrTrialPitAnalysis" => ["Other Supporting Document"],
        "buildingControlCertificate" => ["Building Control Certificate"],
        "conditionSurvey" => ["Other Supporting Document"],
        "constructionInvoice" => ["Construction Invoice"],
        "contaminationReport" => ["Other Supporting Document"],
        "councilTaxBill" => ["Council Tax Document"],
        "crimePreventionStrategy" => ["Council Tax Document"],
        "designAndAccessStatement" => ["Design and Access Statement"],
        "disabilityExemptionEvidence" => ["Other"],
        "ecologyReport" => ["Other Supporting Document"],
        "elevations.existing" => ["Elevation", "Existing"],
        "elevations.proposed" => ["Elevation", "Proposed"],
        "emissionsMitigationAndMonitoringScheme" => ["Other Supporting Document"],
        "energyStatement" => ["Sustainability and Energy Statement"],
        "environmentalImpactAssessment" => ["Environment Impact Assessment"],
        "fireSafetyReport" => ["Other Supporting Document"],
        "floodRiskAssessment" => ["Flood Risk Assessment/Drainage and SuDs Report"],
        "floorPlan.existing" => ["Floor", "Existing"],
        "floorPlan.proposed" => ["Floor", "Proposed"],
        "foulDrainageAssessment" => ["Flood Risk Assessment/Drainage and SuDs Report"],
        "geodiversityAssessment" => ["Other Supporting Document"],
        "heritageStatement" => ["Heritage Statement"],
        "hydrologicalAssessment" => ["Other Supporting Document"],
        "hydrologyReport" => ["Other Supporting Document"],
        "internalElevations" => ["Elevation"],
        "internalSections" => ["Section"],
        "joinersReport" => ["Other Supporting Document"],
        "joinerySections" => ["Other Supporting Document"],
        "landContaminationAssessment" => ["Contaminated Land Assessment"],
        "landscapeAndVisualImpactAssessment" => ["Landscape and Visual Impact Assessment"],
        "landscapeStrategy" => ["Other Supporting Document"],
        "lightingAssessment" => ["Other Supporting Document"],
        "litterVerminAndBirdControlDetails" => ["Other Supporting Document"],
        "locationPlan" => ["Other Supporting Document"],
        "mineralsAndWasteAssessment" => ["Other Supporting Document"],
        "newDwellingsSchedule" => ["Other Supporting Document"],
        "noiseAssessment" => ["Noise Impact Assessment"],
        "openSpaceAssessment" => ["Open Space Assessment"],
        "otherDocument" => ["Other Supporting Document"],
        "otherDrawing" => ["Other Supporting Document"],
        "otherEvidence" => ["Other"],
        "parkingPlan" => ["Other Supporting Document"],
        "photographs.existing" => ["Photograph"],
        "photographs.proposed" => ["Photograph"],
        "planningStatement" => ["Planning Statement"],
        "roofPlan.existing" => ["Roof", "Existing"],
        "roofPlan.proposed" => ["Roof", "Proposed"],
        "sections.existing" => ["Section", "Existing"],
        "sections.proposed" => ["Section", "Proposed"],
        "sitePlan.existing" => ["Site", "Existing"],
        "sitePlan.proposed" => ["Site", "Proposed"],
        "sketchPlan" => ["Other Supporting Document"],
        "statementOfCommunityInvolvement" => ["Other Supporting Document"],
        "statutoryDeclaration" => ["Statutory Declaration"],
        "storageTreatmentAndWasteDisposalDetails" => ["Other Supporting Document"],
        "streetScene" => ["Other Supporting Document"],
        "subsidenceReport" => ["Other Supporting Document"],
        "sunlightAndDaylightReport" => ["Other Supporting Document"],
        "sustainabilityStatement" => ["Sustainability and Energy Statement"],
        "technicalEvidence" => ["Other Supporting Document"],
        "tenancyAgreement" => ["Tenancy Agreement"],
        "tenancyInvoice" => ["Tenancy Invoice"],
        "townCentreImpactAssessment" => ["Other Supporting Document"],
        "townCentreSequentialAssessment" => ["Other Supporting Document"],
        "transportAssessment" => ["Transport Statement"],
        "travelPlan" => ["Other Supporting Document"],
        "treeCanopyCalculator" => ["Other Supporting Document"],
        "treeConditionReport" => ["Other Supporting Document"],
        "treesReport" => ["Other Supporting Document"],
        "unitPlan.existing" => ["Plan", "Existing"],
        "unitPlan.proposed" => ["Plan", "Proposed"],
        "usePlan.existing" => ["Plan", "Existing"],
        "usePlan.proposed" => ["Plan", "Proposed"],
        "utilityBill" => ["Utility Bill"],
        "utilitiesStatement" => ["Other Supporting Document"],
        "ventilationStatement" => ["Ventilation/Extraction Statement"],
        "visualisations" => ["Other Supporting Document"],
        "wasteAndRecyclingStrategy" => ["Other Supporting Document"],
        "waterEnvironmentAssessment" => ["Other Supporting Document"]
      }.freeze

      def initialize(planning_application:, user:, files:)
        @planning_application = planning_application
        @user = user
        @files = files
      end

      def call!
        files.each do |file|
          url = file["name"]
          tags = file["type"].flat_map { |type| MAPPING.fetch(type["value"], []) }.uniq
          description = file["description"]

          UploadDocumentJob.perform_later(planning_application, user, url, tags, description)
        end
      end

      private

      attr_reader :planning_application, :user, :files
    end
  end
end
