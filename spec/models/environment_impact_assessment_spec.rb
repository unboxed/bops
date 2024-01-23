# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnvironmentImpactAssessment do
  subject(:environment_impact_assessment) { build(:environment_impact_assessment) }

  describe "validations" do
    it "has a valid factory" do
      environment_impact_assessment.save

      expect(create(:environment_impact_assessment)).to be_valid
    end

    it "has to have address present if fee is present" do
      environment_impact_assessment.assign_attributes(fee: 197)

      expect do
        environment_impact_assessment.save
      end.to change {
        environment_impact_assessment.errors[:address]
      }.to ["Enter an address where the fee can be paid"]
    end

    it "has to have fee present if address is present" do
      environment_impact_assessment.assign_attributes(address: "123 street")

      expect do
        environment_impact_assessment.save
      end.to change {
        environment_impact_assessment.errors[:fee]
      }.to ["Enter a fee or enter '0' if there is no fee"]
    end
  end

  describe "#after::commit modify_expiry_date" do
    let(:local_authority) { create(:local_authority) }
    let(:assessor) { create(:user, :assessor, local_authority:) }
    let!(:planning_application) do
      travel_to("2024-01-01") { create(:planning_application, local_authority:) }
    end

    it "adds 8 weeks to the expiry date if an EIA is required" do
      expect do
        EnvironmentImpactAssessment.create(planning_application:, required: true)
      end.to change(planning_application, :expiry_date).from("Mon, 26 Feb 2024".to_date).to("Mon, 22 Apr 2024".to_date)
    end

    it "does not get called unless the environment impact assessment value has changed" do
      expect do
        planning_application.update!(postcode: "111XXX")
      end.not_to change(planning_application, :expiry_date)
    end

    context "when planning application has been marked as requiring an EIA" do
      let!(:planning_application) do
        travel_to("2024-01-01") do
          create(:planning_application, local_authority:, target_date: "Mon, 22 Apr 2024".to_date, expiry_date: "Mon, 22 Apr 2024".to_date)
        end
      end
      let!(:environment_impact_assessment) { create(:environment_impact_assessment, planning_application:) }

      it "sets the original expiry date if the EIA is no longer required" do
        expect do
          environment_impact_assessment.update!(required: false)
        end.to change(planning_application, :expiry_date).from("Mon, 22 Apr 2024".to_date).to("Mon, 26 Feb 2024".to_date)
          .and change(Audit, :count).by(1)
      end

      it "does not add an additional 8 weeks to the expiry date if an EIA has already been marked as required" do
        expect do
          environment_impact_assessment.update!(required: true)
        end.not_to change(planning_application, :expiry_date)
      end
    end
  end
end
