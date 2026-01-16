# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::RankedCascadingSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  describe "#applicable?" do
    it "returns false when q param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns true when q param is present" do
      expect(filter.applicable?({q: "test"})).to be true
    end
  end

  describe "#apply" do
    let!(:app1) do
      create(:planning_application,
        local_authority: local_authority,
        postcode: "E1 6AN",
        description: "Some description")
    end

    context "searching by reference" do
      it "finds by reference" do
        params = {q: app1.reference.downcase}
        result = filter.apply(scope, params)

        expect(result).to include(app1)
      end
    end

    context "cascade order with ranked description" do
      it "includes RankedDescriptionSearch in strategies" do
        expect(described_class::STRATEGIES).to eq([
          BopsApi::Filters::TextSearch::ReferenceSearch,
          BopsApi::Filters::TextSearch::PostcodeSearch,
          BopsApi::Filters::TextSearch::AddressSearch,
          BopsApi::Filters::TextSearch::RankedDescriptionSearch
        ])
      end
    end
  end
end
