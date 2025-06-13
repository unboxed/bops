# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "Public Neighbour Responses API", type: :request do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
  let(:consultation) { planning_application.consultation }

  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let!(:api_user) { create(:api_user, :comment_rw, token:, local_authority:) }
  let!(:Authorization) { "Bearer #{token}" }

  path "/api/v2/planning_applications/{reference}/comments/public" do
    post "Submit a public neighbour response" do
      tags "Neighbour Responses"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :reference, in: :path, type: :string, required: true
      parameter name: :body, in: :body, required: false, schema: {
        type: :object,
        properties: {
          address: {type: :string},
          name: {type: :string},
          email: {type: :string},
          response: {type: :string},
          summary_tag: {type: :string},
          tags: {type: :array, items: {type: :string}}
        }
      }

      response "200", "Neighbour response created" do
        let(:reference) { planning_application.reference }
        let(:body) do
          {
            address: "123 Street, London, E1 6LT",
            name: "Jo Blogs",
            email: "jo@example.com",
            response: "I like it",
            summary_tag: "supportive",
            tags: [
              "privacy"
            ]
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json.dig("status", "detail")).to eq("Neighbour response created successfully")
        end
      end

      response "422", "Missing summary_tag" do
        let(:reference) { planning_application.reference }
        let(:body) do
          {
            address: "123 Test Street",
            name: "Test User",
            email: "test@example.com",
            response: "I object"
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          Rails.logger.debug(json)
          expect(json.dig("status", "detail")).to match(/Summary tag can't be blank/)
        end
      end

      response "422", "Missing response" do
        let(:reference) { planning_application.reference }
        let(:body) do
          {
            address: "123 Test Street",
            name: "Test User",
            email: "test@example.com",
            summary_tag: "objection"
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json.dig("status", "detail")).to match(/Response can't be blank/)
        end
      end

      response "400", "Invalid planning application reference" do
        let(:reference) { "invalid-123" }
        let(:body) do
          {
            address: "123 Test Street",
            name: "Test User",
            email: "test@example.com",
            response: "Some response",
            summary_tag: "neutral"
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end
end
