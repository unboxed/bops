# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetail, type: :model do
  describe "validations" do
    subject(:additional_evidence) { described_class.new }

    let(:summary_of_work) { described_class.new }

    describe "#entry" do
      let(:summary_of_work) { create(:assessment_detail, :summary_of_work, entry: "") }
      let(:additional_evidence) { create(:assessment_detail, :additional_evidence, entry: "") }

      it "validates presence for summary of work" do
        expect { summary_of_work }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Entry can't be blank")
      end

      it "does not validate presence for additional evidence" do
        expect { additional_evidence }.not_to raise_error
      end
    end

    describe "#status" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:status] }.to ["can't be blank"]
        expect { additional_evidence.valid? }.to change { additional_evidence.errors[:status] }.to ["can't be blank"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:user] }.to ["must exist"]
        expect { additional_evidence.valid? }.to change { additional_evidence.errors[:user] }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:planning_application] }.to ["must exist"]
        expect { additional_evidence.valid? }.to change { additional_evidence.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:summary_of_works1) { create(:assessment_detail, :summary_of_work, created_at: Time.zone.now - 1.day) }
      let!(:summary_of_works2) { create(:assessment_detail, :summary_of_work, created_at: Time.zone.now) }
      let!(:summary_of_works3) { create(:assessment_detail, :summary_of_work, created_at: Time.zone.now - 2.days) }

      it "returns summary_of_works sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([summary_of_works2, summary_of_works1, summary_of_works3])
      end
    end
  end
end
