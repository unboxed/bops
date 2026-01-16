# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Sorting::Sorter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe "#call" do
    let!(:old_app) do
      create(:planning_application, local_authority: local_authority, received_at: 30.days.ago)
    end

    let!(:recent_app) do
      create(:planning_application, local_authority: local_authority, received_at: 5.days.ago)
    end

    context "with default sorting" do
      let(:sorter) { described_class.new(default_field: "received_at") }
      let(:params) { {} }

      it "sorts by default field in descending order" do
        result = sorter.call(scope, params)

        expect(result.first).to eq(recent_app)
        expect(result.last).to eq(old_app)
      end
    end

    context "with custom sortBy field" do
      let(:sorter) { described_class.new(default_field: "published_at") }
      let(:params) { {sortBy: "receivedAt"} }

      it "sorts by the specified field" do
        result = sorter.call(scope, params)

        expect(result.to_sql).to include("received_at")
      end
    end

    context "with invalid sortBy field" do
      let(:sorter) { described_class.new(default_field: "received_at") }
      let(:params) { {sortBy: "invalid_field"} }

      it "falls back to default field" do
        result = sorter.call(scope, params)

        expect(result.to_sql).to include("received_at")
      end
    end

    context "with ascending order" do
      let(:sorter) { described_class.new(default_field: "received_at") }
      let(:params) { {orderBy: "asc"} }

      it "sorts in ascending order" do
        result = sorter.call(scope, params)

        expect(result.first).to eq(old_app)
        expect(result.last).to eq(recent_app)
      end
    end

    context "with descending order" do
      let(:sorter) { described_class.new(default_field: "received_at") }
      let(:params) { {orderBy: "desc"} }

      it "sorts in descending order" do
        result = sorter.call(scope, params)

        expect(result.first).to eq(recent_app)
        expect(result.last).to eq(old_app)
      end
    end

    context "with lowercase order direction" do
      let(:sorter) { described_class.new(default_field: "received_at") }
      let(:params) { {orderBy: "asc"} }

      it "requires lowercase order direction" do
        result = sorter.call(scope, params)

        expect(result.first).to eq(old_app)
      end
    end

    context "allowed sort fields" do
      it "includes common sort fields" do
        expect(described_class::ALLOWED_FIELDS.keys).to include("publishedAt")
        expect(described_class::ALLOWED_FIELDS.keys).to include("receivedAt")
      end
    end
  end
end
