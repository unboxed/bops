# frozen_string_literal: true

require "rails_helper"

RSpec.describe SummaryOfWork, type: :model do
  describe "validations" do
    subject(:summary_of_work) { described_class.new }

    describe "#entry" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:entry] }.to ["can't be blank"]
      end
    end

    describe "#status" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:status] }.to ["can't be blank"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:user] }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { summary_of_work.valid? }.to change { summary_of_work.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:summary_of_works1) { create(:summary_of_work, created_at: Time.zone.now - 1.day) }
      let!(:summary_of_works2) { create(:summary_of_work, created_at: Time.zone.now) }
      let!(:summary_of_works3) { create(:summary_of_work, created_at: Time.zone.now - 2.days) }

      it "returns summary_of_works sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([summary_of_works2, summary_of_works1, summary_of_works3])
      end
    end
  end
end
