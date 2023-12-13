# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  before do
    create(:local_authority, :default)
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss")
    create(:application_type, :planning_permission)
  end

  let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
  let(:planning_application) { json_fixture("v2/valid_planning_permission.json") }

  path "/api/v2/planning_applications" do
    post "Creates a new plannning application" do
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :planning_application, in: :body, schema: {
        "$ref": "#/components/schemas/Submission"
      }

      request_body_example \
        value: json_fixture("v2/valid_planning_permission.json", symbolize_names: true),
        name: "Planning application",
        summary: "Valid planning permission - full householder"

      response "200", "when the application is created" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        example "application/json", :default, {
          id: "BUC-23-00100-HAPP",
          message: "Application successfully created"
        }

        run_test!
      end

      response "400", "with an invalid request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        example "application/json", :default, {
          error: {
            code: 400,
            message: "Bad Request",
            detail: "We couldn’t process your request because some information is missing or incorrect."
          }
        }

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

      response "403", "when the endpoint is disabled" do
        before do
          allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")
        end

        schema "$ref" => "#/components/schemas/ForbiddenError"

        example "application/json", :default, {
          error: {
            code: 403,
            message: "Forbidden",
            detail: "Creating planning applications using this endpoint is not permitted in production"
          }
        }

        run_test!
      end

      response "404", "when a local authority isn't found" do
        before do
          exception = ActiveRecord::RecordNotFound.new("Local authority not found")
          allow(BopsApi::LocalAuthority).to receive(:find_by!).and_raise(exception)
        end

        schema "$ref" => "#/components/schemas/NotFoundError"

        example "application/json", :default, {
          error: {
            code: 404,
            message: "Not Found",
            detail: "Local authority not found"
          }
        }

        run_test!
      end

      response "422", "when an application is invalid" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        example "application/json", :default, {
          error: {
            code: 422,
            message: "Unprocessable Entity",
            detail: "Planning application is invalid"
          }
        }

        let(:planning_application) { json_fixture("v2/invalid_planning_permission.json") }

        run_test!
      end

      response "500", "when an internal server error occurs" do
        before do
          planning_application = PlanningApplication.new
          exception = ActiveRecord::ConnectionTimeoutError.new("Couldn’t connect to the database")

          allow(PlanningApplication).to receive(:new).and_return(planning_application)
          allow(planning_application).to receive(:save!).and_raise(exception)
        end

        schema "$ref" => "#/components/schemas/InternalServerError"

        example "application/json", :default, {
          error: {
            code: 500,
            message: "Internal Server Error",
            detail: "Couldn’t connect to the database"
          }
        }

        run_test!
      end
    end
  end
end
