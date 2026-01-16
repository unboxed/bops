# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::PostcodeSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".apply" do
    let!(:app1) do
      create(:planning_application, local_authority: local_authority, postcode: "SW1A 1AA")
    end

    let!(:app2) do
      create(:planning_application, local_authority: local_authority, postcode: "E1 6AN")
    end

    context "with valid postcode format" do
      it "returns applications matching the postcode" do
        result = described_class.apply(scope, "sw1a 1aa")

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end

      it "matches postcode without spaces" do
        result = described_class.apply(scope, "sw1a1aa")

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "with non-postcode query" do
      it "returns none" do
        result = described_class.apply(scope, "some random text")

        expect(result).to be_empty
      end
    end

    context "with partial postcode" do
      it "returns none for partial postcodes" do
        result = described_class.apply(scope, "sw1a")

        expect(result).to be_empty
      end
    end
  end
end
