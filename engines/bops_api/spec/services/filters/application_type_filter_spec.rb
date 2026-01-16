# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::ApplicationTypeFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  describe "#applicable?" do
    it "returns false when applicationType param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns true when applicationType param is present" do
      expect(filter.applicable?({applicationType: "ldc"})).to be true
    end
  end

  describe "#apply" do
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
        result = filter.apply(scope, params)

        expect(result).to include(ldc_app)
        expect(result).not_to include(prior_approval_app)
      end
    end

    context "with multiple type codes as array" do
      let(:params) { {applicationType: [ldc_type.code, prior_approval_type.code]} }

      it "filters by all application type codes" do
        result = filter.apply(scope, params)

        expect(result).to include(ldc_app)
        expect(result).to include(prior_approval_app)
      end
    end

    context "with comma-separated type codes" do
      let(:params) { {applicationType: "#{ldc_type.code},#{prior_approval_type.code}"} }

      it "splits and filters by all codes" do
        result = filter.apply(scope, params)

        expect(result).to include(ldc_app)
        expect(result).to include(prior_approval_app)
      end
    end
  end
end
