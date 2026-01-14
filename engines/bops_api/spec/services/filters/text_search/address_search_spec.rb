# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::AddressSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    let!(:app1) do
      create(:planning_application,
        local_authority: local_authority,
        address_1: "10 Downing Street",
        town: "London")
    end

    let!(:app2) do
      create(:planning_application,
        local_authority: local_authority,
        address_1: "221B Baker Street",
        town: "London")
    end

    context "with matching address" do
      it "returns applications matching the address" do
        result = described_class.call(scope, "downing")

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "with multiple terms" do
      it "requires all terms to match (AND logic)" do
        result = described_class.call(scope, "downing street")

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "with common term" do
      it "returns all matching applications" do
        result = described_class.call(scope, "london")

        expect(result).to include(app1)
        expect(result).to include(app2)
      end
    end
  end
end
