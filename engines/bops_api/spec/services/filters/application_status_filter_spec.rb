# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::ApplicationStatusFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  describe "#applicable?" do
    it "returns false when applicationStatus param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns true when applicationStatus param is present" do
      expect(filter.applicable?({applicationStatus: "pending"})).to be true
    end
  end

  describe "#apply" do
    let!(:pending_app) do
      create(:planning_application, :not_started, local_authority: local_authority)
    end

    let!(:in_assessment_app) do
      create(:planning_application, :in_assessment, local_authority: local_authority)
    end

    context "with a single status" do
      let(:params) { {applicationStatus: "not_started"} }

      it "filters by status" do
        result = filter.apply(scope, params)

        expect(result).to include(pending_app)
        expect(result).not_to include(in_assessment_app)
      end
    end

    context "with multiple statuses as array" do
      let(:params) { {applicationStatus: ["not_started", "in_assessment"]} }

      it "filters by all statuses" do
        result = filter.apply(scope, params)

        expect(result).to include(pending_app)
        expect(result).to include(in_assessment_app)
      end
    end

    context "with comma-separated statuses" do
      let(:params) { {applicationStatus: "not_started,in_assessment"} }

      it "splits and filters by all statuses" do
        result = filter.apply(scope, params)

        expect(result).to include(pending_app)
        expect(result).to include(in_assessment_app)
      end
    end
  end
end
