# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConsiderationSet, type: :model do
  describe "#suggested_outcome" do
    let(:consideration_set) { create(:consideration_set) }

    context "when a consideration has 'does_not_comply' tag" do
      before do
        create(:consideration, consideration_set:, summary_tag: "does_not_comply")
      end

      it "returns 'does_not_comply'" do
        expect(consideration_set.suggested_outcome).to eq("does_not_comply")
      end
    end

    context "when no consideration has 'does_not_comply' but at least one has 'needs_changes' tag" do
      before do
        create(:consideration, consideration_set:, summary_tag: "needs_changes")
      end

      it "returns 'needs_changes'" do
        expect(consideration_set.suggested_outcome).to eq("needs_changes")
      end
    end

    context "when all considerations have 'complies' tag" do
      before do
        create(:consideration, consideration_set:, summary_tag: "complies")
        create(:consideration, consideration_set:, summary_tag: "complies")
      end

      it "returns 'complies'" do
        expect(consideration_set.suggested_outcome).to eq("complies")
      end
    end

    context "when there are no considerations" do
      it "returns 'complies' by default" do
        expect(consideration_set.suggested_outcome).to eq("complies")
      end
    end
  end
end
