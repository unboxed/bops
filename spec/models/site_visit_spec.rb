# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteVisit do
  describe "validations" do
    subject(:site_visit) { described_class.new }

    describe "#consultation" do
      it "validates presence" do
        expect { site_visit.valid? }.to change { site_visit.errors[:consultation] }.to ["must exist"]
      end
    end

    describe "#created_by" do
      it "validates presence" do
        expect { site_visit.valid? }.to change { site_visit.errors[:created_by] }.to ["must exist"]
      end
    end

    describe "#decision" do
      it "validates inclusion in [true, false]" do
        expect { site_visit.valid? }.to change { site_visit.errors[:decision] }.to ["Choose 'Yes' or 'No'"]
      end
    end

    describe "#comment" do
      it "validates presence" do
        expect { site_visit.valid? }.to change { site_visit.errors[:comment] }.to ["Enter a comment about the site visit"]
      end
    end

    describe "#visited_at" do
      context "when decision is 'true'" do
        subject(:site_visit) { described_class.new(decision: true) }

        it "validates presence" do
          expect { site_visit.valid? }.to change { site_visit.errors[:visited_at] }.to ["Provide a date when the site visit took place"]
        end
      end

      context "when decision is 'false'" do
        subject(:site_visit) { described_class.new(decision: false) }

        it "does not validate presence" do
          expect { site_visit.valid? }.not_to(change { site_visit.errors[:visited_at] })
        end
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:site_visits1) { create(:site_visit, created_at: 1.day.ago) }
      let!(:site_visits2) { create(:site_visit, created_at: Time.zone.now) }
      let!(:site_visits3) { create(:site_visit, created_at: 2.days.ago) }

      it "returns site_visits sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([site_visits2, site_visits1, site_visits3])
      end
    end
  end
end
