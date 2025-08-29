# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API Public comments" do
  let(:local_authority) { create(:local_authority, :default) }

  def validate_pagination(data, results_per_page:, current_page:, total_results:, total_available_items:)
    expect(data["pagination"]["resultsPerPage"]).to eq(results_per_page)
    expect(data["pagination"]["currentPage"]).to eq(current_page)
    expect(data["pagination"]["totalPages"]).to eq((total_results.to_f / results_per_page).ceil)
    expect(data["pagination"]["totalResults"]).to eq(total_results)
    expect(data["pagination"]["totalAvailableItems"]).to eq(total_available_items)
  end

  def validate_comment_summary(data, total_comments: 50, total_consulted: 50, supportive: 50, objection: 0, neutral: 0)
    expect(data["summary"]["totalComments"]).to eq(total_comments)

    sentiment = data.dig("summary", "sentiment")
    expect(sentiment["supportive"]).to eq(supportive)
    expect(sentiment["objection"]).to eq(objection)
    expect(sentiment["neutral"]).to eq(neutral)
  end

  def validate_comments(data, count:)
    expect(data["comments"].count).to eq(count)
    data["comments"].each do |comment|
      expect(comment["id"]).to be_a(Integer)
      expect(comment["sentiment"]).to be_in(%w[supportive objection neutral])
      expect(comment["comment"]).to include("*****")
      expect { DateTime.iso8601(comment["receivedAt"]) }.not_to raise_error
    end
  end

  path "/api/v2/public/planning_applications/{reference}/comments/public" do
    get "Retrieves published public comments for a planning application" do
      tags "Planning applications"
      produces "application/json"

      # add parameters here

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
            enum: ["supportive", "neutral", "objection"]
          }
        },
        style: :form,
        explode: false,
        required: false

      # Document a standard response based on static json file
      response "200", "Successful operation" do
        example "application/json", "Default response", example_fixture("public/comments_public.json")
        schema "$ref" => "#/components/schemas/CommentsPublicResponse"

        # ensure that the static response is valid against the schema
        it "validates successfully against the example comments_public json" do
          resolved_schema = load_and_resolve_schema(name: "comments_public", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
          schemer = JSONSchemer.schema(resolved_schema)
          example_json = example_fixture("public/comments_public.json")

          expect(schemer.valid?(example_json)).to eq(true)
        end
      end

      context "When running tests on the comments public endpoint" do
        let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

        context "Query params" do
          before do
            50.times do
              neighbour = create(:neighbour, consultation: planning_application.consultation)
              create(:neighbour_response, neighbour: neighbour)
            end
          end

          # no params
          response "200", "Passing no parameters should return correct pagination, summary, and comments", document: false do
            let(:reference) { planning_application.reference }

            run_test! do |response|
              data = JSON.parse(response.body)

              # pagination
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 50, total_available_items: 50)
              # comment summary
              validate_comment_summary(data)
              # comments
              validate_comments(data, count: 10)
            end
          end

          # page, resultsPerPage
          response "200", "Passing page and resultsPerPage params should return correct pagination, summary, and comments", document: false do
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
              validate_comments(data, count: 2)
            end
          end

          # query
          response "200", "Passing query should return correct pagination, summary, and comments", document: false do
            before do
              create(:neighbour_response, response: "rude word not like the other comments", redacted_response: "***** not like the other comments", neighbour: create(:neighbour, consultation: planning_application.consultation))
            end

            let(:reference) { planning_application.reference }
            let(:query) { "not like the other comments" }

            run_test! do |response|
              data = JSON.parse(response.body)

              # pagination
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 51)
              # comment summary
              validate_comment_summary(data, total_comments: 51, total_consulted: 51, supportive: 51, objection: 0, neutral: 0)
              # comments
              validate_comments(data, count: 1)
              expect(data["comments"].first["comment"]).to include("***** not like the other comments")
            end
          end

          # sortBy, orderBy
          response "200", "Passing sortBy and orderBy should return correct pagination, summary, and comments", document: false do
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
        end

        # sentiment
        context "Query params: sentiment" do
          # Helper method to count sentiments in comments
          # This method takes an array of comments and returns a hash with sentiment counts
          def sentiment_counts(comments)
            comments.pluck("sentiment").each_with_object(Hash.new(0)) { |s, h| h[s] += 1 }
          end

          before do
            # create a neighbour response for each sentiment
            NeighbourResponse.summary_tags.keys.each do |sentiment|
              neighbour = create(:neighbour, consultation: planning_application.consultation)
              create(:neighbour_response, summary_tag: sentiment, neighbour: neighbour)
            end
          end

          response "200", "Singular sentiment", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["supportive"] }

            run_test! do |response|
              data = JSON.parse(response.body)

              # pagination
              validate_pagination(data, results_per_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_MAXRESULTS, current_page: BopsApi::Postsubmission::PostsubmissionPagination::DEFAULT_PAGE, total_results: 1, total_available_items: 3)
              # comment summary
              validate_comment_summary(data, total_comments: 3, total_consulted: 3, supportive: 1, objection: 1, neutral: 1)
              # comments
              validate_comments(data, count: 1)

              # Check that only comments with the specified sentiment are returned
              expect(sentiment_counts(data["comments"])).to match_array([["supportive", 1]])
            end
          end

          # ?sentiment=a,b
          response "200", "Multiple sentiments", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["supportive", "objection"] }

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(sentiment_counts(data["comments"])).to match_array([["supportive", 1], ["objection", 1]])
            end
          end

          # ?sentiment=invalid
          response "500", "Invalid sentiments", document: false do
            let(:reference) { planning_application.reference }
            let(:sentiment) { ["invalid"] }

            run_test! do |response|
              data = JSON.parse(response.body)

              expect(data["error"]["code"]).to match(500)
              expect(data["error"]["message"]).to match("Internal Server Error")
              expect(data["error"]["detail"]).to match("Invalid sentiment(s): invalid. Allowed values: supportive, neutral, objection")
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
