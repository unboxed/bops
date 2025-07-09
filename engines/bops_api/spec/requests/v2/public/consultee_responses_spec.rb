# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API Specialist comments" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

  before do
    25.times do
      create(:consultee, :internal, :consulted, responses: build_list(:consultee_response, 1, :with_redaction), consultation: planning_application.consultation)
    end

    25.times do
      create(:consultee, :external, :consulted, responses: build_list(:consultee_response, 1, :with_redaction), consultation: planning_application.consultation)
    end

    25.times do
      create(:consultee, :internal, consultation: planning_application.consultation)
    end

    25.times do
      create(:consultee, :external, consultation: planning_application.consultation)
    end
  end

  path "/api/v2/public/planning_applications/{reference}/comments/specialist" do
    get "Retrieves comments for a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      parameter name: :sortBy, in: :query, schema: {
        type: :string,
        enum: ["id", "receivedAt"],
        default: "receivedAt",
        description: "The sort type for the comments"
      }, required: false

      parameter name: :orderBy, in: :query, schema: {
        type: :string,
        enum: ["asc", "desc"],
        default: "desc",
        description: "The order for the comments"
      }, required: false

      parameter name: :resultsPerPage, in: :query, schema: {
        type: :integer,
        default: 10,
        description: "Max result for page"
      }, required: false

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :query, in: :query, schema: {
        type: :string,
        description: "Search by redacted comment content"
      }, required: false

      parameter name: :sentiment, in: :query, schema: {
        type: :string,
        description: "Search by sentiment"
      }, required: false

      def validate_pagination(data, results_per_page:, current_page:, total_results:, total_available_items:)
        expect(data["pagination"]["resultsPerPage"]).to eq(results_per_page)
        expect(data["pagination"]["currentPage"]).to eq(current_page)
        expect(data["pagination"]["totalPages"]).to eq((total_results.to_f / results_per_page).ceil)
        expect(data["pagination"]["totalResults"]).to eq(total_results)
        expect(data["pagination"]["totalAvailableItems"]).to eq(total_available_items)
      end

      def validate_comment_summary(data)
        expect(data["summary"]["totalComments"]).to eq(50)
        expect(data["summary"]["totalConsulted"]).to eq(100)
        expect(data["summary"]["sentiment"]["approved"]).to eq(50)
        expect(data["summary"]["sentiment"]["amendmentsNeeded"]).to eq(0)
        expect(data["summary"]["sentiment"]["objected"]).to eq(0)
      end

      def validate_comments(data, count:, total_items:)
        expect(data["comments"].count).to eq(count)
        data["comments"].each do |comment|
          expect(comment["id"]).to be_a(Integer)
          expect(comment["sentiment"]).to be_in(["approved", "amendmentsNeeded", "objected"])
          expect(comment["comment"]).to include("*****")
          expect { DateTime.iso8601(comment["receivedAt"]) }.not_to raise_error
        end
      end

      response "200", "returns a planning application's specialist comments given a reference" do
        example "application/json", :default, example_fixture("public/comments_specialist.json")
        schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

        let(:reference) { planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)

          # pagination
          validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 50, total_available_items: 50)

          # comment summary
          validate_comment_summary(data)

          # comments
          validate_comments(data, count: 10, total_items: 50)
        end
      end

      response "200", "returns planning application's specialist comments paginated given a page and resultsPerPage param" do
        let(:reference) { planning_application.reference }
        let(:page) { 2 }
        let(:resultsPerPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          # pagination
          validate_pagination(data, results_per_page: 2, current_page: 2, total_results: 50, total_available_items: 50)

          # comment summary
          validate_comment_summary(data)

          # comments
          validate_comments(data, count: 2, total_items: 50)
        end
      end

      response "200", "returns a planning application's specialist comments filtering by query" do
        before do
          create(:consultee, :external, :consulted, responses: build_list(:consultee_response, 1, :with_redaction, response: "rude word not like the other comments", redacted_response: "***** not like the other comments"), consultation: planning_application.consultation)
        end

        let(:reference) { planning_application.reference }
        let(:query) { "not like the other comments" }

        run_test! do |response|
          data = JSON.parse(response.body)

          # pagination
          validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 51)

          # comment summary
          expect(data["summary"]["totalComments"]).to eq(51)
          expect(data["summary"]["sentiment"]["approved"]).to eq(51)
          expect(data["summary"]["sentiment"]["amendmentsNeeded"]).to eq(0)
          expect(data["summary"]["sentiment"]["objected"]).to eq(0)

          # comments
          validate_comments(data, count: 1, total_items: 1)
          expect(data["comments"].first["comment"]).to include("***** not like the other comments")
        end
      end

      response "200", "returns a planning application's specialist comments filtering by sentiment" do
        before do
          create(:consultee, :external, :consulted, responses: build_list(:consultee_response, 1, :with_redaction, response: "rude word not like the other comments", redacted_response: "***** not like the other comments"), consultation: planning_application.consultation)
        end

        let(:reference) { planning_application.reference }
        let(:sentiment) { "approved" }

        run_test! do |response|
          data = JSON.parse(response.body)

          # pagination
          expect(data["pagination"]["totalPages"]).to eq(6)

          # comment summary
          expect(data["summary"]["totalComments"]).to eq(51)

          # comments
          validate_comments(data, count: 10, total_items: 1)
          expect(data["comments"].first["sentiment"]).to eq("approved")
        end
      end

      response "200", "returns a planning application's specialist comments filtering by sortBy and orderBy" do
        let(:reference) { planning_application.reference }

        context "when sortBy is not set and orderBy is not set " do
          run_test! do |response|
            data = JSON.parse(response.body)
            sorted_values = data["comments"].pluck("receivedAt")
            expect(sorted_values).to eq(sorted_values.sort.reverse) # Descending order
          end
        end

        shared_examples "sortBy and orderBy validation" do |sort_by, order_by, field|
          let(:sortBy) { sort_by }
          let(:orderBy) { order_by }

          run_test! do |response|
            data = JSON.parse(response.body)
            sorted_values = data["comments"].pluck(field)

            expected_order = (order_by == "asc") ? sorted_values.sort : sorted_values.sort.reverse
            expect(sorted_values).to eq(expected_order)
          end
        end

        context "sortBy is id" do
          it_behaves_like "sortBy and orderBy validation", "id", "asc", "id"
          it_behaves_like "sortBy and orderBy validation", "id", "desc", "id"
        end

        context "sortBy is receivedAt" do
          it_behaves_like "sortBy and orderBy validation", "receivedAt", "asc", "receivedAt"
          it_behaves_like "sortBy and orderBy validation", "receivedAt", "desc", "receivedAt"
        end

        context "only sortBy is set" do
          context "sortBy is receivedAt orderBy defaults to desc" do
            let(:sortBy) { "receivedAt" }
            run_test! do |response|
              data = JSON.parse(response.body)
              sorted_values = data["comments"].pluck("receivedAt")
              expect(sorted_values).to eq(sorted_values.sort.reverse) # Descending order
            end
          end

          context "sortBy is id orderBy defaults to asc" do
            let(:sortBy) { "id" }
            run_test! do |response|
              data = JSON.parse(response.body)
              sorted_values = data["comments"].pluck("id")
              expect(sorted_values).to eq(sorted_values.sort) # Ascending order
            end
          end
        end

        context "only orderBy is set" do
          context "orderBy is asc sortBy defaults to receivedAt" do
            let(:orderBy) { "asc" }
            run_test! do |response|
              data = JSON.parse(response.body)
              sorted_values = data["comments"].pluck("receivedAt")
              expect(sorted_values).to eq(sorted_values.sort) # Ascending order
            end
          end

          context "orderBy is desc sortBy defaults to receivedAt" do
            let(:orderBy) { "desc" }
            run_test! do |response|
              data = JSON.parse(response.body)
              sorted_values = data["comments"].pluck("receivedAt")
              expect(sorted_values).to eq(sorted_values.sort.reverse) # Descending order
            end
          end
        end
      end

      response "404", "does not return comments for unpublished planning applications" do
        let(:reference) { planning_application.reference }

        let(:planning_application) { create(:planning_application, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["error"]["message"]).to eq("Not Found")
        end
      end

      it "validates successfully against the example comments_specialist json" do
        resolved_schema = load_and_resolve_schema(name: "comments_specialist", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("public/comments_specialist.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end
end
