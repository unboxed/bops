# frozen_string_literal: true

require "rails_helper"

RSpec.describe EvidenceGroup do
  describe "#comments" do
    let(:immunity_detail) { create(:immunity_detail) }
    let(:document) { create(:document, tags: ["Photograph"]) }

    before do
      immunity_detail.add_document document
    end

    it "can have comments" do
      immunity_detail.evidence_groups.first.comments << create(:comment)
      expect(immunity_detail.evidence_groups.first.comments.first).not_to be_nil
      expect(immunity_detail.evidence_groups.first.comments.first.commentable_type).to eq("EvidenceGroup")
    end
  end
end
