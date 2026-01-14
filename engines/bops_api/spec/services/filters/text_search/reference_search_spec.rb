# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::TextSearch::ReferenceSearch do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    let!(:app1) do
      create(:planning_application, local_authority: local_authority)
    end

    let!(:app2) do
      create(:planning_application, local_authority: local_authority)
    end

    context "with matching reference" do
      it "returns applications matching the reference" do
        # Use the actual generated reference from the factory
        result = described_class.call(scope, app1.reference.downcase)

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "with partial match" do
      it "returns applications with partial reference match" do
        # Use first few characters of the reference
        partial_ref = app1.reference[0..5].downcase
        result = described_class.call(scope, partial_ref)

        expect(result).to include(app1)
      end
    end

    context "with no matches" do
      it "returns empty result" do
        result = described_class.call(scope, "zzznotfound")

        expect(result).to be_empty
      end
    end

    context "case sensitivity" do
      it "uses LIKE with lowercased query against lowercased reference" do
        # The implementation uses: LOWER(reference) LIKE '%query%'
        result = described_class.call(scope, app1.reference.downcase)

        expect(result).to include(app1)
      end
    end
  end
end
