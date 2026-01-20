# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::CascadingSearch do
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

    it "returns true when query param is present" do
      expect(filter.applicable?({query: "test"})).to be true
    end
  end

  describe "#apply" do
    let!(:app1) do
      create(:planning_application,
        local_authority: local_authority,
        postcode: "E1 6AN",
        description: "Some description")
    end

    let!(:app2) do
      create(:planning_application,
        local_authority: local_authority,
        postcode: "SW1A 1AA",
        description: "Another description")
    end

    context "searching by reference" do
      it "finds by reference first" do
        params = {q: app1.reference.downcase}
        result = filter.apply(scope, params)

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "searching by postcode" do
      let(:params) { {q: "SW1A 1AA"} }

      it "finds by postcode when reference doesn't match" do
        result = filter.apply(scope, params)

        expect(result).to include(app2)
        expect(result).not_to include(app1)
      end
    end

    context "cascade order" do
      it "tries reference first, then postcode, then address, then description" do
        expect(described_class::STRATEGIES).to eq([
          BopsCore::Filters::TextSearch::ReferenceSearch,
          BopsCore::Filters::TextSearch::PostcodeSearch,
          BopsCore::Filters::TextSearch::AddressSearch,
          BopsCore::Filters::TextSearch::DescriptionSearch
        ])
      end
    end
  end
end
