# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::CascadingSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when q param is blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params)).to eq(scope)
      end
    end

    context "when q param is present" do
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
          # Use the actual generated reference
          params = {q: app1.reference.downcase}
          result = described_class.call(scope, params)

          expect(result).to include(app1)
          expect(result).not_to include(app2)
        end
      end

      context "searching by postcode" do
        let(:params) { {q: "SW1A 1AA"} }

        it "finds by postcode when reference doesn't match" do
          result = described_class.call(scope, params)

          expect(result).to include(app2)
          expect(result).not_to include(app1)
        end
      end

      context "cascade order" do
        it "tries reference first, then postcode, then address, then description" do
          expect(described_class::STRATEGIES).to eq([
            BopsApi::Filters::TextSearch::ReferenceSearch,
            BopsApi::Filters::TextSearch::PostcodeSearch,
            BopsApi::Filters::TextSearch::AddressSearch,
            BopsApi::Filters::TextSearch::DescriptionSearch
          ])
        end
      end
    end
  end
end
