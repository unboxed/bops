# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationSearch do
  describe "#results" do
    let!(:planning_application1) do
      create(
        :planning_application,
        work_status: "proposed",
        created_at: DateTime.new(2022, 1, 1)
      )
    end

    let!(:planning_application2) { create(:planning_application) }

    let(:planning_applications) do
      PlanningApplication.all
    end

    let(:search) do
      described_class.new(
        query: query,
        planning_applications: PlanningApplication.all
      )
    end

    context "when query is full reference" do
      let(:query) { "22-00100-LDCP" }

      it "returns correct planning applications" do
        expect(search.results).to contain_exactly(planning_application1)
      end
    end

    context "when query is part of reference" do
      let(:query) { "00100" }

      it "returns correct planning applications" do
        expect(search.results).to contain_exactly(planning_application1)
      end
    end

    context "when query is in wrong case" do
      let(:query) { "22-00100-ldcp" }

      it "returns correct planning applications" do
        expect(search.results).to contain_exactly(planning_application1)
      end
    end

    context "when query is blank" do
      let(:query) { nil }

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

    context "when query is has no matches" do
      let(:query) { "qwerty" }

      it "returns no planning applications" do
        expect(search.results).to be_empty
      end
    end
  end
end
