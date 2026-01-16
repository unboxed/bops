# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::DescriptionSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".apply" do
    let!(:garage_app) do
      create(:planning_application,
        local_authority: local_authority,
        description: "Build a new garage for two cars")
    end

    let!(:extension_app) do
      create(:planning_application,
        local_authority: local_authority,
        description: "Single storey rear extension to kitchen")
    end

    context "with matching description term" do
      it "returns applications matching the description" do
        result = described_class.apply(scope, "garage")

        expect(result).to include(garage_app)
        expect(result).not_to include(extension_app)
      end
    end

    context "with multiple terms (OR logic)" do
      it "returns applications matching any term" do
        result = described_class.apply(scope, "garage kitchen")

        expect(result).to include(garage_app)
        expect(result).to include(extension_app)
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
