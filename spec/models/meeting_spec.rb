# frozen_string_literal: true

require "rails_helper"

RSpec.describe Meeting do
  describe "validations" do
    subject(:meeting) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { meeting.valid? }.to change { meeting.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#created_by" do
      it "validates presence" do
        expect { meeting.valid? }.to change { meeting.errors[:created_by] }.to ["must exist"]
      end
    end

    describe "#occurred_at" do
      let!(:planning_application) { create(:planning_application, :pre_application) }

      it "validates presence" do
        meeting = described_class.build

        expect { meeting.save }.to change { meeting.errors[:occurred_at] }.to ["Provide the date when the meeting took place"]
      end
    end

    describe "scopes" do
      describe ".by_occurred_at_desc" do
        let!(:default_local_authority) { create(:local_authority, :default) }
        let!(:planning_application) { create(:planning_application, :pre_application, local_authority: default_local_authority) }
        let!(:meetings1) { create(:meeting, occurred_at: 1.day.ago, planning_application: planning_application) }
        let!(:meetings2) { create(:meeting, occurred_at: Time.zone.now, planning_application: planning_application) }
        let!(:meetings3) { create(:meeting, occurred_at: 2.days.ago, planning_application: planning_application) }

        it "returns meetings sorted by occurred at desc (i.e. most recent first)" do
          expect(described_class.by_occurred_at_desc).to eq([meetings2, meetings1, meetings3])
        end
      end
    end
  end
end
