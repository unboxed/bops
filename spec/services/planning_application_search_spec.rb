# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationSearch do
  describe "#results" do
    let!(:planning_application1) do
      create(
        :planning_application,
        work_status: "proposed",
        created_at: DateTime.new(2022, 1, 1),
        description: "Add a chimney stack."
      )
    end

    let!(:planning_application2) do
      create(:planning_application, description: "Something else entirely")
    end

    let(:search) do
      described_class.new(
        query: query,
        planning_applications: PlanningApplication.all
      )
    end

    context "when query matches description" do
      context "when query is full description" do
        let(:query) { "Add a chimney stack." }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when query is part of description" do
        let(:query) { "chimney" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when query is non-adjacent words from description" do
        let(:query) { "add stack" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when query is in wrong case" do
        let(:query) { "Chimney" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when query contains plurals instead of singulars" do
        let(:query) { "chimneys stacks" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when query contains additional words" do
        let(:query) { "orange chimney stack" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end
      end

      context "when more than one application matches query" do
        let!(:planning_application2) do
          create(:planning_application, description: "Add stack")
        end

        let!(:planning_application3) do
          create(:planning_application, description: "Add orange chimney stack")
        end

        let(:query) { "orange chimney stack" }

        it "returns planning applications ranked by closest match" do
          expect(search.results).to eq(
            [
              planning_application3,
              planning_application1,
              planning_application2
            ]
          )
        end
      end
    end

    context "when query matches reference" do
      context "when query is full reference" do
        let(:query) { "22-00100-LDCP" }

        it "returns correct planning applications" do
          expect(search.results).to contain_exactly(planning_application1)
        end

        it "does not search for matching descriptions" do
          allow(search)
            .to receive(:records_matching_reference)
            .and_call_original

          allow(search).to receive(:records_matching_description)

          search.results

          expect(search).to have_received(:records_matching_reference)
          expect(search).not_to have_received(:records_matching_description)
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
