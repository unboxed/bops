# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::TextSearch::DescriptionSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  let!(:chimney_application) do
    create(:planning_application, local_authority:, description: "Add a chimney stack to the roof")
  end

  let!(:extension_application) do
    create(:planning_application, local_authority:, description: "Add extension to house")
  end

  let!(:non_matching) do
    create(:planning_application, local_authority:, description: "Install solar panels")
  end

  describe ".apply" do
    context "with description search" do
      it "returns applications matching description" do
        result = described_class.apply(scope, "chimney stack")
        expect(result).to include(chimney_application)
        expect(result).not_to include(non_matching)
      end
    end

    context "with single word query" do
      it "returns applications matching that word in the description" do
        result = described_class.apply(scope, "chimney")
        expect(result).to include(chimney_application)
        expect(result).not_to include(extension_application, non_matching)
      end
    end

    context "with plural/singular variations" do
      it "matches stemmed words" do
        result = described_class.apply(scope, "chimneys stacks")
        expect(result).to include(chimney_application)
      end
    end

    context "with multiple matches" do
      it "returns all matching applications" do
        result = described_class.apply(scope, "add extension")

        expect(result.to_a).to eq([extension_application, chimney_application])
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
