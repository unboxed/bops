# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationTypeDocumentTags, type: :model do
  describe "#tag_groups_for_document" do
    let(:document) { instance_double("Document", tags: document_tags) }
    let(:document_tags) { ["floorPlan.proposed", "bankStatement"] }

    subject(:groups) { described_class.new(attributes).tag_groups_for_document(document) }

    context "when no attributes are pre-selected" do
      let(:attributes) do
        {
          drawings: [],
          evidence: [],
          supporting_documents: []
        }
      end

      it "includes only the document’s tags in each group" do
        drawing_group = groups.find { |g| g.name == "drawings" }
        evidence_group = groups.find { |g| g.name == "evidence" }
        supporting_group = groups.find { |g| g.name == "supporting_documents" }

        expect(drawing_group.selected_tags).to contain_exactly("floorPlan.proposed")
        expect(evidence_group.selected_tags).to contain_exactly("bankStatement")
        expect(supporting_group.selected_tags).to be_empty
      end
    end

    context "when attributes have pre-selected values" do
      let(:attributes) do
        {
          drawings: ["roofPlan.existing"],
          evidence: ["councilTaxBill"],
          supporting_documents: []
        }
      end

      it "merges form-selected and document tags into each group" do
        drawing_group = groups.find { |g| g.name == "drawings" }
        evidence_group = groups.find { |g| g.name == "evidence" }

        expect(drawing_group.selected_tags).to match_array(
          ["roofPlan.existing", "floorPlan.proposed"]
        )
        expect(evidence_group.selected_tags).to match_array(
          ["councilTaxBill", "bankStatement"]
        )
      end
    end
  end
end
