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
        let!(:planning_application) { create(:planning_application, :planning_permission) }

        it "validates presence if consultation has started" do
          planning_application.consultation.update!(start_date: Time.zone.now, end_date: 21.days.from_now)
          site_visit = described_class.build(decision: true, consultation: planning_application.consultation)

          expect { site_visit.save }.to change { site_visit.errors[:visited_at] }.to ["Provide the date when the site visit took place"]
        end
      end

      context "when decision is 'false'" do
        subject(:site_visit) { described_class.new(decision: false) }

        it "does not validate presence" do
          expect { site_visit.valid? }.not_to(change { site_visit.errors[:visited_at] })
        end
      end

      describe "consultation_started" do
        subject(:site_visit) { described_class.new(decision: true, visited_at: Time.zone.now, comment: "comment") }

        it "you can't create a site visit without a consultation start date" do
          expect { site_visit.save }.to change { site_visit.errors[:base] }.to ["Start the consultation before creating a site visit"]
        end
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:default_local_authority) { create(:local_authority, :default) }
      let!(:planning_application) { create(:planning_application, :planning_permission, :consulting, local_authority: default_local_authority) }
      let!(:consultation) { planning_application.consultation }
      let!(:site_visits1) { create(:site_visit, created_at: 1.day.ago, consultation: consultation) }
      let!(:site_visits2) { create(:site_visit, created_at: Time.zone.now, consultation: consultation) }
      let!(:site_visits3) { create(:site_visit, created_at: 2.days.ago, consultation: consultation) }

      it "returns site_visits sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([site_visits2, site_visits1, site_visits3])
      end
    end
  end
end
