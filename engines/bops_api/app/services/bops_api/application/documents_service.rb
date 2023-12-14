# frozen_string_literal: true

module BopsApi
  module Application
    class DocumentsService
      MAPPING = {
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
        "proposal.visualisation" => ["Other Supporting Document"]
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
