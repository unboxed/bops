# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::ApplicationTypeFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when applicationType param is blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params)).to eq(scope)
      end
    end

    context "when applicationType param is present" do
      let!(:ldc_type) { create(:application_type, :ldc_proposed, local_authority: local_authority) }
      let!(:prior_approval_type) { create(:application_type, :prior_approval, local_authority: local_authority) }

      let!(:ldc_app) do
        create(:planning_application, local_authority: local_authority, application_type: ldc_type)
      end

      let!(:prior_approval_app) do
        create(:planning_application, local_authority: local_authority, application_type: prior_approval_type)
      end

      context "with a single type code" do
        let(:params) { {applicationType: ldc_type.code} }

        it "filters by the application type code" do
          result = described_class.call(scope, params)

          expect(result).to include(ldc_app)
          expect(result).not_to include(prior_approval_app)
        end
      end

      context "with multiple type codes as array" do
        let(:params) { {applicationType: [ldc_type.code, prior_approval_type.code]} }

        it "filters by all application type codes" do
          result = described_class.call(scope, params)

          expect(result).to include(ldc_app)
          expect(result).to include(prior_approval_app)
        end
      end

      context "with comma-separated type codes" do
        let(:params) { {applicationType: "#{ldc_type.code},#{prior_approval_type.code}"} }

        it "splits and filters by all codes" do
          result = described_class.call(scope, params)

          expect(result).to include(ldc_app)
          expect(result).to include(prior_approval_app)
        end
      end
    end
  end
end
