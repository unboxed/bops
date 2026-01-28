# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::TextSearch::AddressSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  let!(:matching_app) do
    create(:planning_application, local_authority:, address_1: "123 High Street", town: "London")
  end

  let!(:non_matching_app) do
    create(:planning_application, local_authority:, address_1: "456 Park Avenue", town: "Manchester")
  end

  describe ".apply" do
    context "with address words" do
      it "returns applications matching address" do
        result = described_class.apply(scope, "High Street")
        expect(result).to include(matching_app)
        expect(result).not_to include(non_matching_app)
      end
    end

    context "with multiple address words" do
      it "requires all words to match (AND search)" do
        result = described_class.apply(scope, "123 High")
        expect(result).to include(matching_app)
        expect(result).not_to include(non_matching_app)
      end
    end

    context "with no matches" do
      it "returns empty result" do
        result = described_class.apply(scope, "Nonexistent Road")
        expect(result).to be_empty
      end
    end
  end
end
