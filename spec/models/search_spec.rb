# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search do
  describe "#results" do
    let!(:planning_application1) do
      create(
        :planning_application,
        work_status: "proposed",
        created_at: DateTime.new(2022, 1, 1)
      )
    end

    let!(:planning_application2) { create(:planning_application) }

    let(:planning_application_ids) do
      [planning_application1.id, planning_application2.id]
    end

    context "when query is full reference" do
      let(:search) do
        described_class.new(
          query: "22-00100-LDCP",
          planning_application_ids: planning_application_ids
        )
      end

      it "returns correct planning applications" do
        expect(search.results).to contain_exactly(planning_application1)
      end
    end

    context "when query is part of reference" do
      let(:search) do
        described_class.new(
          query: "00100",
          planning_application_ids: planning_application_ids
        )
      end

      it "returns correct planning applications" do
        expect(search.results).to contain_exactly(planning_application1)
      end
    end

    context "when query is blank" do
      let(:search) do
        described_class.new(
          query: nil,
          planning_application_ids: planning_application_ids
        )
      end

      it "returns all planning applications" do
        expect(search.results).to contain_exactly(
          planning_application1, planning_application2
        )
      end

      it "sets error message" do
        search.results

        expect(search.errors.full_messages).to contain_exactly(
          "Query can't be blank"
        )
      end
    end
  end
end
