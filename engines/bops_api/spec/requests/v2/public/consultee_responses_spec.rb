# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API Specialist comments" do
  let(:local_authority) { create(:local_authority, :default) }

  def validate_pagination(data, results_per_page:, current_page:, total_results:, total_available_items:)
    pagination = data["pagination"]
    expect(pagination["resultsPerPage"]).to eq(results_per_page)
    expect(pagination["currentPage"]).to eq(current_page)
    expect(pagination["totalPages"]).to eq((total_results.to_f / results_per_page).ceil)
    expect(pagination["totalResults"]).to eq(total_results)
    expect(pagination["totalAvailableItems"]).to eq(total_available_items)
  end

  def validate_comment_summary(data, total_comments:, total_consulted:, approved:, objected:, amendments_needed:)
    summary = data.dig("data", "summary")
    expect(summary["totalComments"]).to eq(total_comments)
    expect(summary["totalConsulted"]).to eq(total_consulted)

    sentiment = summary["sentiment"]
    expect(sentiment["approved"]).to eq(approved)
    expect(sentiment["objected"]).to eq(objected)
    expect(sentiment["amendmentsNeeded"]).to eq(amendments_needed)
  end

  def validate_specialist_details(data)
    specialists = data.dig("data", "comments")
    expect(specialists).to be_an(Array)
    specialists.each do |specialist|
      expect(specialist["id"]).to be_present
      expect(specialist["organisationSpecialism"]).to be_a(String) if specialist["organisationSpecialism"].present?
      expect { DateTime.iso8601(specialist["firstConsultedAt"]) }.not_to raise_error
      expect(specialist["jobTitle"]).to be_a(String) if specialist["jobTitle"].present?
      expect(specialist["reason"]).to be_in(%w[Constraint Other])
      if specialist["constraints"].present?
        expect(specialist["constraints"]).to be_an(Array)
        specialist["constraints"].each do |constraint|
          expect(constraint["value"]).to be_present
        end
      end
    end
  end

  def validate_comments(data, count:)
    specialists = data.dig("data", "comments")
    expect(specialists).to be_an(Array)
    expect(specialists.size).to eq(count)

    comments = specialists.flat_map { |s| s["comments"] }
    expect(comments.size).to be >= count

    comments.each do |c|
      expect(c["sentiment"]).to be_in(%w[approved objected amendmentsNeeded])
      expect(c["commentRedacted"]).to include("*****")
      expect { DateTime.iso8601(c.dig("metadata", "submittedAt")) }.not_to raise_error
    end
  end

  path "/api/v2/public/planning_applications/{reference}/comments/specialist" do
    get "Retrieves published specialist comments for a planning application" do
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
      parameter name: :sentiment, in: :query,
        description: "Filter by sentiment",
        schema: {
          type: :array,
          items: {
            type: :string,
            enum: ["approved", "amendmentsNeeded", "objected"]
          }
        },
        style: :form,
        explode: false,
        required: false

      # Document a standard response based on static json file
      response "200", "Successful operation" do
        example "application/json", "Default response", example_fixture("public/comments_specialist.json")
        schema "$ref" => "#/components/schemas/CommentsSpecialistResponse"

        # ensure that the static response is valid against the schema
        it "validates successfully against the example comments_specialist json" do
          resolved_schema = load_and_resolve_schema(name: "comments_specialist", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
          schemer = JSONSchemer.schema(resolved_schema)
          example_json = example_fixture("public/comments_specialist.json")

          expect(schemer.valid?(example_json)).to eq(true)
        end
      end

      context "When running tests on the comments specialist endpoint" do
        let!(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }
        let(:consultation) { planning_application.consultation }

        context "Query params" do
          before do
            25.times do
              create(:consultee, :internal, :consulted, responses: build_list(:consultee_response, 1, :with_redaction), consultation: consultation)
            end
            25.times do
              create(:consultee, :external, :consulted, responses: build_list(:consultee_response, 1, :with_redaction), consultation: consultation)
            end
            25.times do
              create(:consultee, :internal, consultation: consultation)
            end
            25.times do
              create(:consultee, :external, consultation: consultation)
            end
          end

          response "200", "Passing no parameters should return correct pagination, summary, and comments", document: false do
            let(:reference) { planning_application.reference }

            run_test! do |response|
              data = JSON.parse(response.body)
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 50, total_available_items: 50)
              validate_comment_summary(data, total_comments: 50, total_consulted: 50, approved: 50, objected: 0, amendments_needed: 0)
              validate_specialist_details(data)
              validate_comments(data, count: 10)
            end
          end

          response "200", "Passing page and resultsPerPage returns correct pagination, summary, and comments", document: false do
            let(:reference) { planning_application.reference }
            let(:page) { 2 }
            let(:resultsPerPage) { 2 }

            run_test! do |response|
              data = JSON.parse(response.body)
              validate_pagination(data, results_per_page: 2, current_page: 2, total_results: 50, total_available_items: 50)
              validate_comment_summary(data, total_comments: 50, total_consulted: 50, approved: 50, objected: 0, amendments_needed: 0)
              validate_specialist_details(data)
              validate_comments(data, count: 2)
            end
          end

          response "200", "Passing query should return correct pagination, summary, and comments", document: false do
            before do
              create(:consultee, :external, :consulted, consultation: consultation) do |consultee|
                create(:consultee_response, :with_redaction, consultee: consultee, redacted_response: "***** not like the other comments")
              end
            end

            let(:reference) { planning_application.reference }
            let(:query) { "not like the other comments" }

            run_test! do |response|
              data = JSON.parse(response.body)
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 51)
              validate_comment_summary(data, total_comments: 51, total_consulted: 51, approved: 51, objected: 0, amendments_needed: 0)
              validate_comments(data, count: 1)
              validate_specialist_details(data)
            end
          end

          response "200", "Passing sortBy and orderBy returns correctly sorted comments", document: false do
            let(:reference) { planning_application.reference }

            context "when sortBy is not set and orderBy is not set" do
              run_test! do |response|
                data = JSON.parse(response.body)
                values = data.dig("data", "comments").map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                expect(values).to eq(values.sort.reverse)
              end
            end

            shared_examples "sortBy and orderBy validation" do |sort_by, order_by, field|
              let(:sortBy) { sort_by }
              let(:orderBy) { order_by }

              run_test! do |response|
                data = JSON.parse(response.body)
                specs = data.dig("data", "comments")
                sorted_values = specs.map do |s|
                  c = s["comments"].first
                  (field == "receivedAt") ? Time.zone.parse(c["metadata"]["submittedAt"]) : c[field]
                end
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
                  values = data.dig("data", "comments").map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                  expect(values).to eq(values.sort.reverse)
                end
              end

              context "sortBy is id, orderBy defaults to asc" do
                let(:sortBy) { "id" }
                run_test! do |response|
                  data = JSON.parse(response.body)
                  values = data.dig("data", "comments").map { |s| s["comments"].first["id"] }
                  expect(values).to eq(values.sort)
                end
              end
            end

            context "when only orderBy is set" do
              context "orderBy is asc, sortBy defaults to receivedAt" do
                let(:orderBy) { "asc" }
                run_test! do |response|
                  data = JSON.parse(response.body)
                  values = data.dig("data", "comments").map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                  expect(values).to eq(values.sort)
                end
              end

              context "orderBy is desc, sortBy defaults to receivedAt" do
                let(:orderBy) { "desc" }
                run_test! do |response|
                  data = JSON.parse(response.body)
                  values = data.dig("data", "comments").map { |s| Time.zone.parse(s["comments"].first["metadata"]["submittedAt"]) }
                  expect(values).to eq(values.sort.reverse)
                end
              end
            end
          end
        end

        context "Query params: sentiment" do
          def sentiment_counts(specialist_comments)
            comments = specialist_comments.flat_map { |s| s["comments"] }
            comments.pluck("sentiment").each_with_object(Hash.new(0)) { |s, h| h[s] += 1 }
          end

          before do
            Consultee::Response.summary_tags.keys.each do |sentiment|
              create(:consultee, :consulted, responses: build_list(:consultee_response, 1, :with_redaction, summary_tag: sentiment), consultation: planning_application.consultation)
            end
          end

          response "200", "Singular sentiment", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["amendmentsNeeded"] }

            run_test! do |response|
              data = JSON.parse(response.body)
              specialists = data.dig("data", "comments")
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 3)
              validate_comment_summary(data, total_comments: 3, total_consulted: 3, approved: 1, objected: 1, amendments_needed: 1)
              validate_comments(data, count: 1)
              sentiment_counts = sentiment_counts(specialists)
              expect(sentiment_counts).to eq("amendmentsNeeded" => 1)
            end
          end

          response "200", "filters correctly for multiple sentiments", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["approved", "objected"] }

            run_test! do |response|
              data = JSON.parse(response.body)
              specialists = data.dig("data", "comments")
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: 1, total_results: 2, total_available_items: 3)
              validate_comment_summary(data, total_comments: 3, total_consulted: 3, approved: 1, objected: 1, amendments_needed: 1)
              validate_comments(data, count: 2)
              sentiment_counts = sentiment_counts(specialists)
              expect(sentiment_counts).to eq("approved" => 1, "objected" => 1)
            end
          end

          response "500", "Invalid sentiments", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["amendments_needed", "invalid"] }

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data["error"]["code"]).to eq(500)
              expect(data["error"]["message"]).to eq("Internal Server Error")
              expect(data["error"]["detail"]).to match("Invalid sentiment(s): amendments_needed, invalid. Allowed values: approved, amendmentsNeeded, objected")
            end
          end
        end

        context "Comment summary" do
          response "200", "no redacted responses gives a count of zero", document: false do
            before do
              create(:consultee, :consulted, responses: [build(:consultee_response)], consultation: consultation)
              create(:consultee, :consulted, responses: [build(:consultee_response)], consultation: consultation)
            end

            let(:reference) { planning_application.reference }

            run_test! do |response|
              data = JSON.parse(response.body)
              summary = data.dig("data", "summary")
              expect(summary["totalConsulted"]).to eq(2)
              expect(summary["totalComments"]).to eq(0)
              expect(summary["sentiment"].values).to all(eq(0))
              expect(data.dig("data", "comments")).to eq([])
            end
          end

          response "200", "only consultees with redacted responses are counted", document: false do
            before do
              create(:consultee, :consulted, responses: [build(:consultee_response, :with_redaction)], consultation: consultation)
              create(:consultee, :consulted, responses: [build(:consultee_response)], consultation: consultation)
            end

            let(:reference) { planning_application.reference }

            run_test! do |response|
              data = JSON.parse(response.body)
              summary = data.dig("data", "summary")
              expect(summary["totalConsulted"]).to eq(2)
              expect(summary["totalComments"]).to eq(1)
              expect(summary["sentiment"].values.sum).to eq(1)
              expect(data.dig("data", "comments").size).to eq(1)
            end
          end

          response "200", "latest response sentiment is used for multiple redacted comments", document: false do
            before do
              create(:consultee, :consulted, consultation: consultation) do |c|
                # Older redacted response:
                create(:consultee_response, :with_redaction, consultee: c, summary_tag: "objected", received_at: 2.days.ago)
                # Newer redacted response:
                create(:consultee_response, :with_redaction, consultee: c, summary_tag: "approved", received_at: 1.hour.ago)
              end
            end

            let(:reference) { planning_application.reference }

            run_test! do |response|
              data = JSON.parse(response.body)
              summary = data.dig("data", "summary")
              expect(summary["totalConsulted"]).to eq(1)
              expect(summary["totalComments"]).to eq(1)
              expect(summary["sentiment"]["approved"]).to eq(1)
              expect(summary["sentiment"]["objected"]).to eq(0)
              comments = data.dig("data", "comments").flat_map { |s| s["comments"] }
              expect(comments.count).to eq(2)
              expect(comments.max_by { |c| c.dig("metadata", "submittedAt") }["sentiment"]).to eq("approved")
            end
          end
        end
      end

      # Document: Planning application does not exist
      response "404", "The requested resource was not found" do
        schema "$ref" => "#/components/schemas/NotFoundError"

        let(:planning_application) { create(:planning_application, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

        let(:reference) { planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Not Found")
        end
      end

      # Document: Planning application reference is invalid
      response "400", "The request was invalid or cannot be served" do
        schema "$ref" => "#/components/schemas/BadRequestError"
      end
    end
  end
end
