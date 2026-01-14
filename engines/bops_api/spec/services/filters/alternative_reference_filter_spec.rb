# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::AlternativeReferenceFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when alternativeReference param is blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params)).to eq(scope)
      end
    end

    context "when alternativeReference param is present" do
      let!(:app_with_alt_ref) do
        create(:planning_application, local_authority: local_authority, alternative_reference: "M3-2024-001")
      end

      let!(:app_without_alt_ref) do
        create(:planning_application, local_authority: local_authority, alternative_reference: nil)
      end

      let!(:app_with_different_alt_ref) do
        create(:planning_application, local_authority: local_authority, alternative_reference: "X9-2024-999")
      end

      context "with exact match" do
        let(:params) { {alternativeReference: "M3-2024-001"} }

        it "filters by alternative reference" do
          result = described_class.call(scope, params)

          expect(result).to include(app_with_alt_ref)
          expect(result).not_to include(app_without_alt_ref)
          expect(result).not_to include(app_with_different_alt_ref)
        end
      end

      context "with partial match" do
        let(:params) { {alternativeReference: "M3"} }

        it "filters using LIKE matching" do
          result = described_class.call(scope, params)

          expect(result).to include(app_with_alt_ref)
          expect(result).not_to include(app_without_alt_ref)
          expect(result).not_to include(app_with_different_alt_ref)
        end
      end

      context "with case-insensitive matching" do
        let(:params) { {alternativeReference: "m3-2024"} }

        it "matches regardless of case" do
          result = described_class.call(scope, params)

          expect(result).to include(app_with_alt_ref)
          expect(result).not_to include(app_with_different_alt_ref)
        end
      end
    end
  end
end
