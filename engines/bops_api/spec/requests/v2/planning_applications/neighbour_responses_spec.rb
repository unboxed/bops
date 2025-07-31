# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "Neighbour Responses API", type: :request do
  let(:local_authority) { create(:local_authority, :default) }
  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let!(:api_user) { create(:api_user, :comment_rw, token:, local_authority:) }
  let!(:Authorization) { "Bearer #{token}" }

  valid_neighbour_response = {name: "Jo Blogs", address: "123 street, AAA111", response: "I like it", summary_tag: "supportive", tags: ["light"]}

  path "/api/v2/planning_applications/{reference}/comments/public" do
    post "Accepts a neighbour response" do
      tags "Neighbour Responses"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      # add parameters here
      parameter name: :reference, in: :path, type: :string, required: false

      parameter name: :body, in: :body, required: true, schema: {
        "$ref" => "#/components/schemas/NeighbourResponseSubmission"
      }

      # request examples for swagger
      request_body_example(value: valid_neighbour_response, name: "Supportive neighbour response", summary: "Supportive neighbour response")

      # Document a standard response based on static json file
      response "200", "Successful operation" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        # create a planning application
        let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

        # request
        let(:reference) { planning_application.reference }
        let(:body) { valid_neighbour_response }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(reference)
          expect(data["message"]).to eq("Response submitted")
        end
      end

      # Document: Request is invalid
      response "400", "Bad Request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        # create a planning application
        let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority:) }

        # request
        let(:reference) { planning_application.reference }
        # missing required data
        let(:body) { valid_neighbour_response.merge(summary_tag: nil) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Bad Request")
          expect(data["error"]["detail"]).to start_with("Validation failed:")
        end
      end

      # Document: User is not authorised
      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        # request
        let(:Authorization) { nil }
        let(:reference) { "25-00000-HAPP" }
        let(:body) { valid_neighbour_response }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Unauthorized")
        end
      end

      # Document: Planning application does not exist
      response "404", "Not Found" do
        schema "$ref" => "#/components/schemas/NotFoundError"

        # request
        let(:reference) { "25-00000-HAPP" }
        let(:body) { valid_neighbour_response }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Not Found")
        end
      end

      # Document: Planning application cannot accept neighbour responses
      response "500", "Internal server error" do
        schema "$ref" => "#/components/schemas/InternalServerError"

        # create a planning application that cannot accept neighbour responses
        let(:application_type) { create(:application_type, :without_consultation) }
        let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:, application_type:) }

        # request
        let(:reference) { planning_application.reference }
        let(:body) { valid_neighbour_response }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["message"]).to eq("Internal Server Error")
          expect(data["error"]["detail"]).to eq("This application type cannot accept neighbour responses")
        end
      end
    end
  end
end
