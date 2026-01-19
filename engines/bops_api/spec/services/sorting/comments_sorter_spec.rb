# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Sorting::CommentsSorter do
  let(:local_authority) { create(:local_authority) }
  let(:planning_application) { create(:planning_application, local_authority:) }
  let(:consultation) { create(:consultation, planning_application:) }
  let(:neighbour) { create(:neighbour, consultation:) }

  let(:allowed_fields) do
    {
      "receivedAt" => {column: "received_at", default_order: "desc"},
      "id" => {column: "neighbour_responses.id", default_order: "asc"}
    }
  end

  let(:sorter) { described_class.new(allowed_fields:) }

  describe "#call" do
    let!(:older_response) do
      create(:neighbour_response, neighbour:, received_at: 2.days.ago)
    end
    let!(:newer_response) do
      create(:neighbour_response, neighbour:, received_at: 1.day.ago)
    end

    let(:scope) { NeighbourResponse.all }

    context "with default sorting" do
      it "sorts by receivedAt desc by default" do
        result = sorter.call(scope, {})

        expect(result.first).to eq(newer_response)
        expect(result.last).to eq(older_response)
      end
    end

    context "with explicit sortBy" do
      it "sorts by specified field" do
        result = sorter.call(scope, {sortBy: "id"})

        expect(result.first.id).to be < result.last.id
      end

      it "uses field's default order when orderBy not specified" do
        result = sorter.call(scope, {sortBy: "receivedAt"})

        expect(result.first).to eq(newer_response)
      end
    end

    context "with explicit orderBy" do
      it "sorts ascending when orderBy is asc" do
        result = sorter.call(scope, {orderBy: "asc"})

        expect(result.first).to eq(older_response)
        expect(result.last).to eq(newer_response)
      end

      it "sorts descending when orderBy is desc" do
        result = sorter.call(scope, {orderBy: "desc"})

        expect(result.first).to eq(newer_response)
        expect(result.last).to eq(older_response)
      end
    end

    context "with both sortBy and orderBy" do
      it "applies both parameters" do
        result = sorter.call(scope, {sortBy: "id", orderBy: "desc"})

        expect(result.first.id).to be > result.last.id
      end
    end

    context "with invalid sortBy" do
      it "falls back to default field" do
        result = sorter.call(scope, {sortBy: "invalidField"})

        expect(result.first).to eq(newer_response)
        expect(result.last).to eq(older_response)
      end
    end

    context "with invalid orderBy" do
      it "falls back to field's default order" do
        result = sorter.call(scope, {orderBy: "invalid"})

        expect(result.first).to eq(newer_response)
        expect(result.last).to eq(older_response)
      end
    end
  end

  describe "with custom default_field" do
    let(:sorter) { described_class.new(allowed_fields:, default_field: "id") }

    it "uses custom default field" do
      scope = NeighbourResponse.all

      result = sorter.call(scope, {})

      expect(result.to_sql).to include("neighbour_responses.id")
    end
  end
end
