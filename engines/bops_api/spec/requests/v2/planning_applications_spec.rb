# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  valid_planning_permission_json = File.read(Rails.root.join("spec", "fixtures", "files", "v2", "valid_planning_permission.json"))
  valid_prior_approval_json = File.read(Rails.root.join("spec", "fixtures", "files", "v2", "valid_prior_approval.json"))
  let(:planning_application) { JSON.parse(valid_planning_permission_json, symbolize_names: true) }

  before do
    create(:local_authority, :default)
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss")
    create(:application_type, :lawfulness_certificate)
    create(:application_type, :prior_approval)
    create(:application_type, :planning_permission)
  end

  path "/api/v2/planning_applications" do
    post "Creates a new plannning application" do
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :planning_application, in: :body, schema: {
        "$ref": "#/components/schemas/Submission"
      }

      request_body_example value: JSON.parse(valid_planning_permission_json, symbolize_names: true), name: "Planning application", summary: "Valid planning permission - full householder"

      response "200", "when the application is created" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        example "application/json", :default, {
          id: "BUC-23-00100-HAPP",
          message: "Application successfully created"
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }

        run_test!
      end

      response "400", "with an invalid request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

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
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }

        run_test!
      end

      response "404", "when a local authority isn't found" do
        before do
          allow(BopsApi::LocalAuthority).to receive(:find_by!).with(subdomain: "planx").and_raise(ActiveRecord::RecordNotFound)
        end

        schema "$ref" => "#/components/schemas/NotFoundError"

        example "application/json", :default, {
          error: {
            code: 404,
            message: "Not found"
          }
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
        let(:planning_application) { JSON.parse(valid_planning_permission_json, symbolize_names: true) }

        run_test!
      end

      response "500", "when an internal server error occurs" do
        before do
          planning_application = PlanningApplication.new
          allow(PlanningApplication).to receive(:new).and_return(planning_application)
          allow(planning_application).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
        end

        schema "$ref" => "#/components/schemas/InternalServerError"

        example "application/json", :default, {
          error: {
            code: 500,
            message: "Internal server error"
          }
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
        let(:planning_application) { JSON.parse(valid_planning_permission_json, symbolize_names: true) }

        run_test!
      end
    end
  end
end
