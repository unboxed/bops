# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::CouncilDecisionFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when councilDecision param is blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params)).to eq(scope)
      end
    end

    context "when councilDecision param is present" do
      let!(:granted_app) do
        create(:planning_application, :determined, local_authority: local_authority, decision: "granted")
      end

      let!(:refused_app) do
        create(:planning_application, :determined, local_authority: local_authority, decision: "refused")
      end

      let!(:undetermined_app) do
        create(:planning_application, :in_assessment, local_authority: local_authority)
      end

      context "filtering by granted" do
        let(:params) { {councilDecision: "granted"} }

        it "returns only granted applications" do
          result = described_class.call(scope, params)

          expect(result).to include(granted_app)
          expect(result).not_to include(refused_app)
          expect(result).not_to include(undetermined_app)
        end
      end

      context "filtering by refused" do
        let(:params) { {councilDecision: "refused"} }

        it "returns only refused applications" do
          result = described_class.call(scope, params)

          expect(result).not_to include(granted_app)
          expect(result).to include(refused_app)
          expect(result).not_to include(undetermined_app)
        end
      end
    end
  end
end
