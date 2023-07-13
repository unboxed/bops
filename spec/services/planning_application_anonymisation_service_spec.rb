# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationAnonymisationService, type: :service do
  describe "#call!" do
    let!(:local_authority) { create(:local_authority) }

    let(:anonymise_planning_application) do
      described_class.new(planning_application:).call!
    end

    context "when planning application is from production" do
      let!(:planning_application) { create(:planning_application, local_authority:, from_production: true) }

      it "anonymises the personal information on a planning application" do
        anonymise_planning_application

        expect(planning_application).to have_attributes(
          from_production: true,
          applicant_first_name: "XXXXX",
          applicant_last_name: "XXXXX",
          applicant_phone: "XXXXX",
          applicant_email: "applicant@example.com",
          agent_first_name: "XXXXX",
          agent_last_name: "XXXXX",
          agent_phone: "XXXXX",
          agent_email: "agent@example.com"
        )
      end

      context "when there is an ActiveRecord::RecordInvalid error saving the new planning application" do
        before { allow_any_instance_of(PlanningApplication).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }

        it "raises an error" do
          expect { anonymise_planning_application }.to raise_error(described_class::AnonymiseError)
        end
      end
    end

    context "when planning application is not from production" do
      let!(:planning_application) { create(:planning_application, local_authority:, from_production: false) }

      it "raises an error" do
        expect { anonymise_planning_application }.to raise_error(described_class::AnonymiseError, "Anonymizing is only permitted for production cases.")
      end
    end
  end
end
