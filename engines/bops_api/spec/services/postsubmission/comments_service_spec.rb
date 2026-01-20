# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Postsubmission::CommentsService do
  describe "#call" do
    context "with NeighbourResponse scope" do
      let!(:consultation) { create(:consultation, :started) }
      let!(:neighbour) { create(:neighbour, source: "sent_comment", consultation:) }
      let(:scope) { NeighbourResponse.all }
      let(:params) { {} }
      let(:service) { described_class.new(scope, params) }

      describe "basic processing" do
        let!(:responses) { create_list(:neighbour_response, 3, neighbour:) }

        it "returns paginated results" do
          pagy, result = service.call

          expect(pagy).to be_a(Pagy)
          expect(result.count).to eq(3)
        end

        it "returns empty results for empty scope" do
          NeighbourResponse.delete_all
          _, result = service.call

          expect(result).to be_empty
        end
      end

      describe "query filter" do
        let!(:matching) { create(:neighbour_response, neighbour:, redacted_response: "I love this proposal") }
        let!(:non_matching) { create(:neighbour_response, neighbour:, redacted_response: "No comment") }

        it "filters by query text" do
          _, result = described_class.new(scope, {query: "love"}).call

          expect(result).to include(matching)
          expect(result).not_to include(non_matching)
        end

        it "performs case-insensitive search" do
          _, result = described_class.new(scope, {query: "LOVE"}).call

          expect(result).to include(matching)
        end

        it "matches partial text" do
          _, result = described_class.new(scope, {query: "propos"}).call

          expect(result).to include(matching)
        end

        it "ignores empty query" do
          _, result = described_class.new(scope, {query: ""}).call

          expect(result).to include(matching, non_matching)
        end

        it "returns empty when no matches found" do
          _, result = described_class.new(scope, {query: "xyz123notfound"}).call

          expect(result).to be_empty
        end
      end

      describe "sentiment filter" do
        let!(:supportive) { create(:neighbour_response, neighbour:, summary_tag: "supportive") }
        let!(:neutral) { create(:neighbour_response, neighbour:, summary_tag: "neutral") }
        let!(:objection) { create(:neighbour_response, neighbour:, summary_tag: "objection") }

        it "filters by single sentiment" do
          _, result = described_class.new(scope, {sentiment: ["supportive"]}).call

          expect(result).to contain_exactly(supportive)
        end

        it "filters by multiple sentiments" do
          _, result = described_class.new(scope, {sentiment: ["supportive", "objection"]}).call

          expect(result).to contain_exactly(supportive, objection)
        end

        it "returns all sentiments when not specified" do
          _, result = described_class.new(scope, {}).call

          expect(result).to contain_exactly(supportive, neutral, objection)
        end

        it "accepts string sentiment parameter" do
          _, result = described_class.new(scope, {sentiment: "neutral"}).call

          expect(result).to contain_exactly(neutral)
        end
      end

      describe "sorting" do
        let!(:older) { create(:neighbour_response, neighbour:, received_at: 3.days.ago) }
        let!(:middle) { create(:neighbour_response, neighbour:, received_at: 2.days.ago) }
        let!(:newer) { create(:neighbour_response, neighbour:, received_at: 1.day.ago) }

        it "sorts by receivedAt desc by default" do
          _, result = service.call

          expect(result.to_a).to eq([newer, middle, older])
        end

        it "sorts by receivedAt asc when specified" do
          _, result = described_class.new(scope, {sortBy: "receivedAt", orderBy: "asc"}).call

          expect(result.to_a).to eq([older, middle, newer])
        end

        it "sorts by id asc" do
          _, result = described_class.new(scope, {sortBy: "id", orderBy: "asc"}).call

          expect(result.first.id).to be < result.last.id
        end

        it "sorts by id desc" do
          _, result = described_class.new(scope, {sortBy: "id", orderBy: "desc"}).call

          expect(result.first.id).to be > result.last.id
        end

        it "falls back to default for invalid sortBy" do
          _, result = described_class.new(scope, {sortBy: "invalid"}).call

          expect(result.to_a).to eq([newer, middle, older])
        end

        it "falls back to field default order for invalid orderBy" do
          _, result = described_class.new(scope, {sortBy: "receivedAt", orderBy: "invalid"}).call

          expect(result.to_a).to eq([newer, middle, older])
        end
      end

      describe "pagination" do
        let!(:responses) { create_list(:neighbour_response, 15, neighbour:) }

        it "returns default 10 results per page" do
          pagy, result = service.call

          expect(pagy.limit).to eq(10)
          expect(result.count).to eq(10)
        end

        it "respects resultsPerPage parameter" do
          pagy, result = described_class.new(scope, {resultsPerPage: 5}).call

          expect(pagy.limit).to eq(5)
          expect(result.count).to eq(5)
        end

        it "caps resultsPerPage at 50" do
          pagy, _ = described_class.new(scope, {resultsPerPage: 100}).call

          expect(pagy.limit).to eq(50)
        end

        it "returns second page of results" do
          pagy, result = described_class.new(scope, {page: 2, resultsPerPage: 5}).call

          expect(pagy.page).to eq(2)
          expect(result.count).to eq(5)
        end

        it "handles page beyond available data" do
          pagy, result = described_class.new(scope, {page: 100}).call

          expect(pagy.page).to eq(pagy.last)
          expect(result).not_to be_empty
        end
      end

      describe "combined filters" do
        let!(:supportive_match) do
          create(:neighbour_response, neighbour:, summary_tag: "supportive",
            redacted_response: "Great project", received_at: 1.day.ago)
        end
        let!(:supportive_no_match) do
          create(:neighbour_response, neighbour:, summary_tag: "supportive",
            redacted_response: "Wonderful idea", received_at: 2.days.ago)
        end
        let!(:objection_match) do
          create(:neighbour_response, neighbour:, summary_tag: "objection",
            redacted_response: "Bad project", received_at: 3.days.ago)
        end

        it "applies query and sentiment filters together" do
          _, result = described_class.new(scope, {
            query: "project",
            sentiment: ["supportive"]
          }).call

          expect(result).to contain_exactly(supportive_match)
        end

        it "applies all filters with sorting" do
          _, result = described_class.new(scope, {
            query: "project",
            sentiment: ["supportive", "objection"],
            sortBy: "receivedAt",
            orderBy: "asc"
          }).call

          expect(result.to_a).to eq([objection_match, supportive_match])
        end
      end
    end

    context "with Consultee::Response scope" do
      let!(:consultation) { create(:consultation, :started) }
      let!(:consultee) { create(:consultee, :internal, :consulted, consultation:) }
      let(:scope) { Consultee::Response.all }
      let(:params) { {} }
      let(:service) { described_class.new(scope, params) }

      describe "basic processing" do
        let!(:responses) { create_list(:consultee_response, 3, consultee:) }

        it "returns paginated results" do
          pagy, result = service.call

          expect(pagy).to be_a(Pagy)
          expect(result.count).to eq(3)
        end
      end

      describe "query filter" do
        let!(:matching) { create(:consultee_response, consultee:, redacted_response: "Approved with conditions") }
        let!(:non_matching) { create(:consultee_response, consultee:, redacted_response: "No issues") }

        it "filters by query text" do
          _, result = described_class.new(scope, {query: "conditions"}).call

          expect(result).to include(matching)
          expect(result).not_to include(non_matching)
        end
      end

      describe "sentiment filter" do
        let!(:approved) { create(:consultee_response, consultee:, summary_tag: "approved") }
        let!(:amendments_needed) { create(:consultee_response, consultee:, summary_tag: "amendments_needed") }
        let!(:objected) { create(:consultee_response, consultee:, summary_tag: "objected") }

        it "filters by approved sentiment" do
          _, result = described_class.new(scope, {sentiment: ["approved"]}).call

          expect(result).to contain_exactly(approved)
        end

        it "filters by amendmentsNeeded sentiment (camelCase)" do
          _, result = described_class.new(scope, {sentiment: ["amendmentsNeeded"]}).call

          expect(result).to contain_exactly(amendments_needed)
        end

        it "filters by objected sentiment" do
          _, result = described_class.new(scope, {sentiment: ["objected"]}).call

          expect(result).to contain_exactly(objected)
        end

        it "filters by multiple sentiments" do
          _, result = described_class.new(scope, {sentiment: ["approved", "objected"]}).call

          expect(result).to contain_exactly(approved, objected)
        end
      end

      describe "sorting" do
        let!(:older) { create(:consultee_response, consultee:, received_at: 2.days.ago) }
        let!(:newer) { create(:consultee_response, consultee:, received_at: 1.day.ago) }

        it "sorts by receivedAt desc by default" do
          _, result = service.call

          expect(result.first).to eq(newer)
          expect(result.last).to eq(older)
        end

        it "sorts by id using correct table name" do
          _, result = described_class.new(scope, {sortBy: "id", orderBy: "asc"}).call

          expect(result.first.id).to be < result.last.id
        end
      end
    end

    context "validation" do
      let!(:consultation) { create(:consultation, :started) }
      let!(:neighbour) { create(:neighbour, consultation:) }
      let!(:response) { create(:neighbour_response, neighbour:) }
      let(:scope) { NeighbourResponse.all }

      it "raises ArgumentError for invalid sentiment" do
        service = described_class.new(scope, {sentiment: ["invalid"]})

        expect { service.call }.to raise_error(ArgumentError, /Invalid sentiment/)
      end

      it "raises ArgumentError with list of allowed values" do
        service = described_class.new(scope, {sentiment: ["badvalue"]})

        expect { service.call }.to raise_error(ArgumentError, /supportive.*neutral.*objection/i)
      end

      it "raises ArgumentError for mixed valid and invalid sentiments" do
        service = described_class.new(scope, {sentiment: ["supportive", "invalid"]})

        expect { service.call }.to raise_error(ArgumentError, /Invalid sentiment.*invalid/)
      end
    end

    context "model class derivation" do
      let!(:consultation) { create(:consultation, :started) }
      let!(:neighbour) { create(:neighbour, consultation:) }
      let!(:consultee) { create(:consultee, :internal, :consulted, consultation:) }

      it "correctly derives NeighbourResponse from scope" do
        create(:neighbour_response, neighbour:, summary_tag: "supportive")
        scope = NeighbourResponse.all

        _, result = described_class.new(scope, {sentiment: ["supportive"]}).call

        expect(result.count).to eq(1)
      end

      it "correctly derives Consultee::Response from scope" do
        create(:consultee_response, consultee:, summary_tag: "approved")
        scope = Consultee::Response.all

        _, result = described_class.new(scope, {sentiment: ["approved"]}).call

        expect(result.count).to eq(1)
      end

      it "uses correct table name for sorting" do
        create_list(:neighbour_response, 2, neighbour:)
        scope = NeighbourResponse.all

        _, result = described_class.new(scope, {sortBy: "id"}).call

        expect(result.to_sql).to include("neighbour_responses.id")
      end

      it "uses correct table name for consultee responses sorting" do
        create_list(:consultee_response, 2, consultee:)
        scope = Consultee::Response.all

        _, result = described_class.new(scope, {sortBy: "id"}).call

        expect(result.to_sql).to include("consultee_responses.id")
      end
    end
  end
end
