# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::ApplicationTypeFilter do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  let!(:application_type_ldc_proposed) { create(:application_type, :ldc_proposed, local_authority:) }
  let!(:application_type_prior_approval) { create(:application_type, :prior_approval, local_authority:) }
  let!(:application_type_householder) { create(:application_type, :householder, local_authority:) }

  let!(:ldc_app) do
    create(:planning_application, local_authority:, application_type: application_type_ldc_proposed)
  end

  let!(:prior_approval_app) do
    create(:planning_application, local_authority:, application_type: application_type_prior_approval)
  end

  let!(:householder_app) do
    create(:planning_application, local_authority:, application_type: application_type_householder)
  end

  describe "#applicable?" do
    it "returns false when application_type param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns false when application_type is nil" do
      expect(filter.applicable?({application_type: nil})).to be false
    end

    it "returns true when application_type param is present" do
      expect(filter.applicable?({application_type: [application_type_ldc_proposed.name]})).to be true
    end
  end

  describe "#apply" do
    context "with single application type" do
      let(:params) { {application_type: [application_type_ldc_proposed.name]} }

      it "returns only applications of that type" do
        result = filter.apply(scope, params)
        expect(result).to include(ldc_app)
        expect(result).not_to include(prior_approval_app, householder_app)
      end
    end

    context "with multiple application types" do
      let(:params) do
        {
          application_type: [
            application_type_ldc_proposed.name,
            application_type_prior_approval.name
          ]
        }
      end

      it "returns applications matching any type" do
        result = filter.apply(scope, params)
        expect(result).to include(ldc_app, prior_approval_app)
        expect(result).not_to include(householder_app)
      end
    end

    context "with invalid application type" do
      let(:params) { {application_type: ["nonexistent_type"]} }

      it "ignores the filter and returns the scope unchanged" do
        result = filter.apply(scope, params)
        expect(result).not_to be_empty
      end
    end
  end
end
