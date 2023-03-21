# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audit do
  describe "validations" do
    subject(:audit) { described_class.new }

    describe "#activity_type" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:activity_type] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#validation_request" do
      let(:planning_application) { create(:planning_application) }
      let(:audit) { planning_application.audits.last }

      context "when there is an associated request" do
        let!(:validation_request) do
          create(
            :red_line_boundary_change_validation_request,
            planning_application:
          )
        end

        it "returns the correct request" do
          expect(audit.validation_request).to eq(validation_request)
        end
      end

      context "when there is no associated request" do
        it "returns nil" do
          expect(audit.validation_request).to be_nil
        end
      end
    end
  end

  describe "scopes" do
    describe ".most_recent_for_planning_applications" do
      let!(:user1) { create(:user, name: "Assigned Officer") }
      let!(:audits1) { create(:audit, created_at: 3.days.ago, planning_application: planning_application1) }
      let!(:audits2) { create(:audit, created_at: 1.day.ago, planning_application: planning_application2) }
      let!(:audits3) { create(:audit, created_at: 4.days.ago, planning_application: planning_application3) }

      let(:planning_application1) do
        travel_to(10.days.ago) { create(:planning_application) }
      end
      let(:planning_application2) do
        travel_to(10.days.ago) { create(:planning_application) }
      end
      let(:planning_application3) do
        travel_to(10.days.ago) { create(:planning_application) }
      end
      # Create planning application that has an officer assigned
      let(:planning_application4) do
        travel_to(10.days.ago) { create(:planning_application, user: user1) }
      end

      before do
        create(:audit, created_at: 2.days.ago, planning_application: planning_application2)
        create(:audit, created_at: 5.days.ago, planning_application: planning_application3)
        create(:audit, created_at: 6.days.ago, planning_application: planning_application3)
        create(:audit, created_at: 5.days.ago, planning_application: planning_application4, user: user1)
      end

      it "returns the most recent audits that was made by a user other than the assigned officer for each planning application sorted by created at desc" do
        expect(
          described_class.most_recent_for_planning_applications
        ).to eq([audits2, audits1, audits3])
      end

      context "when a new audit is created for a planning application" do
        before do
          create(:audit, planning_application: planning_application3)
        end

        it "returns the most recent audits that was made by a user other than the assigned officer for each planning application sorted by created at desc" do
          expect(
            described_class.most_recent_for_planning_applications
          ).to eq([described_class.last, audits2, audits1])
        end
      end
    end
  end
end
