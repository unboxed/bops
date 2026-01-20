# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::TextSearch::PostcodeSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  let!(:matching_app) do
    create(:planning_application, local_authority:, postcode: "SW1A 1AA")
  end

  let!(:non_matching_app) do
    create(:planning_application, local_authority:, postcode: "E1 6AN")
  end

  describe ".apply" do
    context "with postcode format query" do
      it "returns applications with matching postcode" do
        result = described_class.apply(scope, "SW1A 1AA")
        expect(result).to include(matching_app)
        expect(result).not_to include(non_matching_app)
      end
    end

    context "with postcode without spaces" do
      it "matches postcode regardless of spacing" do
        result = described_class.apply(scope, "SW1A1AA")
        expect(result).to include(matching_app)
      end
    end

    context "with lowercase postcode" do
      it "matches case-insensitively" do
        result = described_class.apply(scope, "sw1a 1aa")
        expect(result).to include(matching_app)
      end
    end

    context "with non-postcode query" do
      it "returns empty result" do
        result = described_class.apply(scope, "some text")
        expect(result).to be_empty
      end
    end
  end
end
