# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::StatusFilter do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  let!(:not_started_app) do
    create(:planning_application, :not_started, local_authority:)
  end

  let!(:in_assessment_app) do
    create(:planning_application, :in_assessment, local_authority:)
  end

  let!(:closed_app) do
    create(:planning_application, :closed, local_authority:)
  end

  describe "#applicable?" do
    it "returns false when status param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns false when status is empty array" do
      expect(filter.applicable?({status: []})).to be false
    end

    it "returns false when status array contains only empty strings" do
      expect(filter.applicable?({status: ["", ""]})).to be false
    end

    it "returns true when status param is present" do
      expect(filter.applicable?({status: ["not_started"]})).to be true
    end
  end

  describe "#apply" do
    context "with single status" do
      let(:params) { {status: ["not_started"]} }

      it "returns only applications with matching status" do
        result = filter.apply(scope, params)
        expect(result).to include(not_started_app)
        expect(result).not_to include(in_assessment_app, closed_app)
      end
    end

    context "with multiple statuses" do
      let(:params) { {status: %w[not_started in_assessment]} }

      it "returns applications matching any of the statuses" do
        result = filter.apply(scope, params)
        expect(result).to include(not_started_app, in_assessment_app)
        expect(result).not_to include(closed_app)
      end
    end

    context "with status array containing empty strings" do
      let(:params) { {status: ["not_started", "", ""]} }

      it "ignores empty strings and filters by remaining statuses" do
        result = filter.apply(scope, params)
        expect(result).to include(not_started_app)
        expect(result).not_to include(in_assessment_app, closed_app)
      end
    end

    context "with invalid status" do
      let(:params) { {status: ["nonexistent_status"]} }

      it "returns no applications" do
        result = filter.apply(scope, params)
        expect(result).to be_empty
      end
    end
  end
end
