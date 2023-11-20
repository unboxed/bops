# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  valid_planning_permission_json = File.read(Rails.root.join("spec", "fixtures", "files", "v2", "valid_planning_permission.json"))
  let(:planning_application) { JSON.parse(valid_planning_permission_json, symbolize_names: true) }

  before do
    create(:local_authority, :default)
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss")
    create(:application_type, :prior_approval)
    create(:application_type)
    create(:application_type, :planning_permission)
  end

  path "/api/v2/planning_applications" do
    post "Creates a new plannning application" do
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :planning_application, in: :body, schema: {
        "$ref": "#/components/schemas/planning_application"
      }

      request_body_example value: JSON.parse(valid_planning_permission_json, symbolize_names: true), name: "Planning application", summary: "Valid planning permission - full householder"

      response "200", "Application successfully created" do
        schema type: :object,
          properties: {
            id: {type: :string},
            message: {type: :string}
          },
          required: %w[id message]

        example "application/json", :default, {
          id: "BUC-23-00100-HAPP",
          message: "Application successfully created"
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }

        run_test!
      end

      response "400", "Bad request" do
        schema "$ref" => "#/components/schemas/errors/properties/bad_request"

        example "application/json", :default, {
          error: {
            code: 400,
            message: "Bad Request"
          }
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
        let(:planning_application) { {} }

        run_test!
      end

      response "401", "with missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/errors/properties/unauthorized"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }

        run_test!
      end
    end
  end
end
