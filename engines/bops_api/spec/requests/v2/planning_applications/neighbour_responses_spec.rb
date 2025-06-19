# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Public Neighbour Responses API", type: :request do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
  let(:consultation) { planning_application.consultation }
  let!(:neighbour) { create(:neighbour, consultation:, address: "123 Test Street, London, W1 1AA") }

  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let!(:api_user) { create(:api_user, token:, local_authority:) }
  let!(:Authorization) { "Bearer #{token}" }

  path "/api/v2/planning_applications/{reference}/comments/public" do
    post "Submit a public neighbour response" do
      tags "Neighbour Responses"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :reference, in: :path, type: :string, description: "Planning Application Reference"
      parameter name: :neighbour_response, in: :body, schema: {
        type: :object,
        properties: {
          address: {type: :string},
          name: {type: :string},
          email: {type: :string},
          response: {type: :string},
          summary_tag: {type: :string},
          tags: {
            type: :array,
            items: {type: :string}
          }
        },
        required: ["address", "response"]
      }

      ### ✅ SUCCESS ###
      response "201", "neighbour response created" do
        let(:reference) { planning_application.reference }
        let(:neighbour_response) do
          {
            address: "123 Test Street, London, W1 1AA",
            name: "Jane Smith",
            email: "jane@example.com",
            response: "I am concerned about noise levels.",
            summary_tag: "objection",
            tags: ["parking", "privacy"]
          }
        end

        example "application/json", :default, {
          message: "Neighbour response created successfully"
        }

        run_test!
      end

      ### ❌ MISSING RESPONSE ###
      response "422", "missing required response text" do
        let(:reference) { planning_application.reference }
        let(:neighbour_response) do
          {
            address: "123 Test Street, London, W1 1AA",
            name: "Jane Smith",
            email: "jane@example.com"
          }
        end

        example "application/json", :missing_response, {
          error: "Response can't be blank"
        }

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["error"]).to match(/Response/i)
        end
      end

      ### ❌ MISSING SUMMARY TAG ###
      response "422", "missing required summary tag" do
        let(:reference) { planning_application.reference }
        let(:neighbour_response) do
          {
            name: "Jane Smith",
            email: "jane@example.com",
            response: "I object to this."
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          # expect(JSON.parse(response.body)["error"]).to match(/Summary tag can't be blank/i)
          expect(JSON.parse(response.body)["error"]).to eq("Validation failed: Summary tag can't be blank")
        end
      end

      ### ❌ APPLICATION NOT FOUND ###
      response "400", "planning application not found" do
        let(:reference) { "nonexistent-ref-999" }
        let(:neighbour_response) do
          {
            address: "Somewhere",
            name: "John Doe",
            email: "john@example.com",
            response: "Noise issues"
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["error"]["detail"]).to match(/Invalid planning application reference or id: "nonexistent-ref-999/i)
        end
      end

      ### ❌ SIMULATED SERVICE ERROR ###
      # response "422", "internal service failure" do
      #   before do
      #     allow_any_instance_of(NeighbourResponseCreationService).to receive(:call)
      #       .and_raise(NeighbourResponse::NeighbourResponseCreationService::CreateError, "Unexpected validation issue")
      #   end

      #   let(:reference) { planning_application.reference }
      #   let(:neighbour_response) do
      #     {
      #       address: "123 Test Street, London, W1 1AA",
      #       name: "Error Tester",
      #       response: "Fails on purpose"
      #     }
      #   end

      #   run_test! do |response|
      #     expect(response).to have_http_status(:unprocessable_entity)
      #     expect(JSON.parse(response.body)["error"]).to match(/Unexpected validation issue/)
      #   end
      # end
    end
  end
end
