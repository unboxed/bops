# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetailsCreationService, type: :service do
  describe "#call" do
    let(:api_user) { create(:api_user) }

    context "when a planning application is provided" do
      let!(:planning_application) { create(:planning_application, :from_planx_immunity, api_user:) }

      # Documents have already been created by the time this service is called
      let!(:document1) { create(:document, tags: ["Proposed", "Utility Bill"], planning_application:) }
      let!(:document2) { create(:document, tags: ["Proposed", "Utility Bill"], planning_application:) }
      let!(:document3) { create(:document, tags: ["Proposed", "Building Control Certificate"], planning_application:) }

      context "when successful" do
        it "creates a the immunity details for the planning application" do
          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(ImmunityDetail, :count).by(1)

          immunity_detail = ImmunityDetail.last

          expect(immunity_detail).to have_attributes(
            planning_application_id: planning_application.id,
            status: "not_started",
            end_date: "2015-02-01".to_date
          )

          expect(EvidenceGroup.count).to eq 2
        end

        it "creates a the evidence groups for the planning application" do
          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(EvidenceGroup, :count).by(2)

          utility_bills = planning_application.immunity_detail.evidence_groups.where(tag: "utility_bill").first

          expect(utility_bills).to have_attributes(
            immunity_detail_id: planning_application.immunity_detail.id,
            start_date: "2013-03-02".to_date,
            end_date: "2019-04-01".to_date,
            applicant_comment: "That i was paying water bills"
          )

          expect(utility_bills.documents).to include(document1, document2)

          building_certificate = planning_application.immunity_detail.evidence_groups.where(tag: "building_control_certificate").first

          expect(building_certificate).to have_attributes(
            immunity_detail_id: planning_application.immunity_detail.id,
            start_date: "2016-02-01".to_date,
            end_date: nil,
            applicant_comment: "that it was certified"
          )

          expect(building_certificate.documents).to eq [document3]
        end
      end

      context "when not successful" do
        let!(:planning_application) { create(:planning_application, :from_planx, api_user:) }

        it "rescues from the error" do
          expect do
            described_class.new(
              planning_application:
            ).call
          end.not_to change(ImmunityDetail, :count)

          expect do
            described_class.new(
              planning_application:
            ).call
          end.not_to raise_error
        end
      end
    end
  end
end
