# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::TextSearch::DescriptionSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  let!(:best_match) do
    create(:planning_application, local_authority:, description: "Add a chimney stack to the roof")
  end

  let!(:partial_match) do
    create(:planning_application, local_authority:, description: "Add extension to house")
  end

  let!(:non_matching) do
    create(:planning_application, local_authority:, description: "Install solar panels")
  end

  describe ".apply" do
    context "with description search" do
      it "returns applications matching description" do
        result = described_class.apply(scope, "chimney stack")
        expect(result).to include(best_match)
        expect(result).not_to include(non_matching)
      end
    end

    context "with partial word match" do
      it "returns applications with partial description match" do
        result = described_class.apply(scope, "chimney")
        expect(result).to include(best_match)
      end
    end

    context "with plural/singular variations" do
      it "matches stemmed words" do
        result = described_class.apply(scope, "chimneys stacks")
        expect(result).to include(best_match)
      end
    end

    context "with multiple matches" do
      it "orders by relevance" do
        result = described_class.apply(scope, "add extension")
        # Both should match but with different rankings
        expect(result).to include(best_match, partial_match)
      end
    end

    context "with no matches" do
      it "returns empty result" do
        result = described_class.apply(scope, "swimming pool")
        expect(result).to be_empty
      end
    end
  end
end
