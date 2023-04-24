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
end
