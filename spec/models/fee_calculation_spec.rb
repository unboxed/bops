# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeeCalculation, type: :model do
  context "when the data aligns with the ODP schema" do
    it "creates an object from the data" do
      json_data = %({
        "calculated": 206,
        "payable": 0,
        "exemption": {
          "disability": true,
          "resubmission": true
        },
        "reduction": {
          "sports": true,
          "parishCouncil": true,
          "alternative": true
        },
        "reference": {
          "govPay": "sandbox-ref-456"
        }
      })
      data = JSON.parse(json_data, symbolize_names: true)
      calculation = FeeCalculation.from_odp_data(data)
      expect(calculation.total_fee).to eq 206
      expect(calculation.payable_fee).to eq 0
      expect(calculation.exemptions).to eq ["disability", "resubmission"]
      expect(calculation.reductions).to eq ["sports", "parishCouncil", "alternative"]
    end
  end

  context "when the data aligns with the Planning Portal schema" do
    it "creates an object from the data" do
      json_data = %({
        "fullFee": {
          "enlargementImprovementAlteration": true,
          "newDwellinghouses": false,
          "changeToMultipleDwellinghouses": false,
          "changeBuildingToDwellinghouses": false,
          "buildingErection": false,
          "agriculturalBuildingErection": false,
          "glasshouseErection": false,
          "plantOrMachinery": false,
          "refuseOrWasteMaterials": false,
          "otherOperations": false,
          "meansOfAccess": false,
          "otherMaterialChange": false,
          "fee": 206,
          "enlargementImprovementAlterationSingleOrMultiple": "enlargementImprovementAlterationSingle"
        },
        "concessions": {
          "reductions": {
            "parishCouncil": true
          },
          "exemptions": {
            "disabledAccess": true,
            "disabledAccessPublic": true,
            "planningActPart3": true,
            "firstRevision": true
          }
        },
        "multipleLpaFees": {
          "isMultipleLpa": false
        },
        "calculation": {
          "payment": {
            "amountDue": 0.00,
            "currency": "GBP",
            "paymentMethod": "OnlineViaPortal"
          }
        }
      })
      data = JSON.parse(json_data, symbolize_names: true)
      calculation = FeeCalculation.from_planning_portal_data(data)
      expect(calculation.total_fee).to eq 206
      expect(calculation.payable_fee).to eq 0
      expect(calculation.exemptions).to eq ["disabledAccess", "disabledAccessPublic", "planningActPart3", "firstRevision"]
      expect(calculation.reductions).to eq ["parishCouncil"]
    end
  end
end
