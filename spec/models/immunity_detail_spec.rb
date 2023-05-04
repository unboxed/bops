# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImmunityDetail do
  describe "validations" do
    it "has a valid factory" do
      expect(create(:immunity_detail)).to be_valid
    end

    it "validates presence of status" do
      immunity_detail = build(:immunity_detail, status: "", review_status: "review_not_started")
      expect { immunity_detail.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Status can't be blank")
    end

    it "validates presence of review status" do
      immunity_detail = build(:immunity_detail, status: "not_started", review_status: "")
      expect { immunity_detail.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Review status can't be blank")
    end
  end

  describe "#add_document" do
    let(:immunity_detail) { create(:immunity_detail) }
    let(:document) { create(:document, tags: ["Council Tax Document"]) }

    it "can have a document added" do
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups).not_to be_empty
      expect(immunity_detail.evidence_groups.first.tag).to eq("council_tax_document")
      expect(immunity_detail.evidence_groups.first.documents.first).to eq(document)
    end

    it "uses only evidence tags on a document" do
      document.tags = ["Elevation", "Council Tax Document"]
      document.save!
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups.first.tag).to eq("council_tax_document")
    end

    it "ignores multiple evidence tags on a document" do
      document.tags = ["Council Tax Document", "Photograph"]
      document.save!
      immunity_detail.add_document document
      expect(immunity_detail.evidence_groups.first.tag).to eq("council_tax_document")
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
