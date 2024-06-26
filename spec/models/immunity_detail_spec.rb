# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetail do
  describe "validations" do
    it "has a valid factory" do
      expect(create(:immunity_detail)).to be_valid
    end
  end

  describe "callbacks" do
    describe "::after_update #create_evidence_review_immunity_detail" do
      let!(:planning_application) do
        create(:planning_application, :not_started)
      end
      let!(:immunity_detail) do
        create(:immunity_detail, planning_application:)
      end

      context "when there is already an evidence review immunity detail record pending review" do
        before do
          create(:review, :evidence, owner: immunity_detail)
        end

        it "does not create a new evidence review immunity detail record" do
          expect do
            immunity_detail.update(end_date: Time.zone.now)
          end.not_to change(Review, :count)
        end
      end
    end
  end

  describe "#add_document" do
    let(:immunity_detail) { create(:immunity_detail) }
    let(:document) { create(:document, tags: %w[councilTaxBill]) }

    it "can have a document added" do
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups).not_to be_empty
      expect(immunity_detail.evidence_groups.first.tag).to eq("councilTaxBill")
      expect(immunity_detail.evidence_groups.first.documents.first).to eq(document)
    end

    it "uses only evidence tags on a document" do
      document.tags = ["elevations.existing", "councilTaxBill"]
      document.save!
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups.first.tag).to eq("councilTaxBill")
    end

    it "ignores multiple evidence tags on a document" do
      document.tags = ["councilTaxBill", "photographs.existing"]
      document.save!
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups.first.tag).to eq("councilTaxBill")
    end
  end

  describe "#evidence_gaps?" do
    let(:immunity_detail) { create(:immunity_detail) }

    it "returns false when there isn't missing evidence" do
      create(:evidence_group, missing_evidence: false, immunity_detail:)
      create(:evidence_group, missing_evidence: false, immunity_detail:)

      expect(immunity_detail.evidence_gaps?).to be false
    end

    it "returns true when there is missing evidence" do
      create(:evidence_group, missing_evidence: false, immunity_detail:)
      create(:evidence_group, missing_evidence: false, immunity_detail:)
      create(:evidence_group, missing_evidence: true, immunity_detail:)

      expect(immunity_detail.evidence_gaps?).to be true
    end

    it "doesn't blow up if there's no evidence" do
      expect(immunity_detail.evidence_gaps?).to be_nil
    end
  end

  describe "#earliest_evidence_cover" do
    let(:immunity_detail) { create(:immunity_detail) }

    it "returns the earliest start date" do
      evidence_group = create(:evidence_group, start_date: 4.years.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 1.year.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 2.years.ago, end_date: nil, immunity_detail:)

      expect(immunity_detail.earliest_evidence_cover).to eq(evidence_group.start_date)
    end

    it "doesn't blow up if there are no start dates" do
      create(:evidence_group, start_date: nil, immunity_detail:)
      create(:evidence_group, start_date: nil, immunity_detail:)

      expect(immunity_detail.earliest_evidence_cover).to be_nil
    end
  end

  describe "#latest_evidence_cover" do
    let(:immunity_detail) { create(:immunity_detail) }

    it "returns the latest end date" do
      evidence_group = create(:evidence_group, start_date: 5.years.ago, end_date: 2.weeks.ago, immunity_detail:)
      create(:evidence_group, start_date: 1.year.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 6.years.ago, end_date: 2.years.ago, immunity_detail:)

      expect(immunity_detail.latest_evidence_cover).to eq(evidence_group.end_date)
    end

    it "doesn't blow up if there are no end dates" do
      create(:evidence_group, start_date: nil, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: nil, end_date: nil, immunity_detail:)

      expect(immunity_detail.latest_evidence_cover).to be_nil
    end

    it "returns a start date if there are no end dates" do
      evidence_group = create(:evidence_group, start_date: 1.year.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 5.years.ago, end_date: nil, immunity_detail:)

      expect(immunity_detail.latest_evidence_cover).to eq(evidence_group.start_date)
    end

    it "returns a later start date than end date if appropriate" do
      evidence_group = create(:evidence_group, start_date: 2.weeks.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 1.year.ago, end_date: nil, immunity_detail:)
      create(:evidence_group, start_date: 6.years.ago, end_date: 2.years.ago, immunity_detail:)

      expect(immunity_detail.latest_evidence_cover).to eq(evidence_group.start_date)
    end
  end
end
