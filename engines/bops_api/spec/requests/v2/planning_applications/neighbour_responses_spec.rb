require "swagger_helper"

RSpec.describe "Public Neighbour Responses API" do
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
          address: { type: :string },
          name: { type: :string },
          email: { type: :string },
          response: { type: :string },
          summary_tag: { type: :string }
        },
        required: ["address", "response"]
      }

      response "201", "neighbour response created" do
        let(:reference) { planning_application.reference }
        # let(:consultation) { planning_application.consultation }

        let(:neighbour_response) do
          {
            address: "123 Test Street, London, W1 1AA",
            name: "Jane Smith",
            email: "jane@example.com",
            response: "I am concerned about noise levels.",
            summary_tag: "objection"
          }
        end

        example "application/json", :default, {
          address: "123 Test Street, London, W1 1AA",
          name: "Jane Smith",
          email: "jane@example.com",
          response: "I am concerned about noise levels.",
          summary_tag: "concern"
        }

        run_test! do |response|
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json).to include("message")
        end
      end

      response "422", "invalid input" do
        let(:reference) { planning_application.reference }
        let(:neighbour_response) do
          {
            address: "123 Test Street, London, W1 1AA",
            name: "Jane Smith",
            email: "jane@example.com",
          }
        end

        example "application/json", :invalid, {
          errors: ["Neighbour must exist", "Response can't be blank"]
        }

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["errors"]).to include("Response can't be blank")
        end
      end
    end
  end
end


