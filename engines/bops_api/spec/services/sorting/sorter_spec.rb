# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Sorting::Sorter do
  describe "#call" do
    context "with default fields" do
      let(:local_authority) { create(:local_authority) }
      let(:scope) { PlanningApplication.where(local_authority: local_authority) }
      let(:sorter) { described_class.new }

      let!(:old_app) do
        create(:planning_application, local_authority: local_authority, received_at: 30.days.ago)
      end
      let!(:recent_app) do
        create(:planning_application, local_authority: local_authority, received_at: 5.days.ago)
      end

      it "sorts by received_at desc by default" do
        result = sorter.call(scope, {})

        expect(result.first).to eq(recent_app)
        expect(result.last).to eq(old_app)
      end

      it "converts camelCase sortBy to snake_case" do
        result = sorter.call(scope, {sortBy: "receivedAt"})

        expect(result.to_sql).to include("received_at")
      end

      it "falls back to default field for invalid sortBy" do
        result = sorter.call(scope, {sortBy: "invalidField"})

        expect(result.to_sql).to include("received_at")
      end

      it "sorts ascending when orderBy is asc" do
        result = sorter.call(scope, {orderBy: "asc"})

        expect(result.first).to eq(old_app)
        expect(result.last).to eq(recent_app)
      end

      it "sorts descending when orderBy is desc" do
        result = sorter.call(scope, {orderBy: "desc"})

        expect(result.first).to eq(recent_app)
        expect(result.last).to eq(old_app)
      end

      it "uses custom default_field" do
        sorter = described_class.new(default_field: "published_at")
        result = sorter.call(scope, {})

        expect(result.to_sql).to include("published_at")
      end
    end

    context "with custom fields" do
      let(:local_authority) { create(:local_authority) }
      let(:planning_application) { create(:planning_application, local_authority:) }
      let(:consultation) { create(:consultation, planning_application:) }
      let(:neighbour) { create(:neighbour, consultation:) }

      let(:allowed_fields) do
        {
          "received_at" => {column: "received_at", default_order: "desc"},
          "id" => {column: "neighbour_responses.id", default_order: "asc"}
        }
      end

      let(:sorter) { described_class.new(allowed_fields:) }
      let(:scope) { NeighbourResponse.all }

      let!(:older_response) do
        create(:neighbour_response, neighbour:, received_at: 2.days.ago)
      end
      let!(:newer_response) do
        create(:neighbour_response, neighbour:, received_at: 1.day.ago)
      end

      it "uses column from config" do
        result = sorter.call(scope, {sortBy: "id"})

        expect(result.to_sql).to include("neighbour_responses.id")
      end

      it "uses field's default order" do
        result = sorter.call(scope, {sortBy: "id"})

        expect(result.first.id).to be < result.last.id
      end

      it "overrides default order with explicit orderBy" do
        result = sorter.call(scope, {sortBy: "id", orderBy: "desc"})

        expect(result.first.id).to be > result.last.id
      end
    end

    describe "DEFAULT_FIELDS" do
      it "defaults column to key when not specified" do
        described_class::DEFAULT_FIELDS.each do |key, config|
          expect(config[:column] || key).to eq(key)
        end
      end
    end
  end
end
