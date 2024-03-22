# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:southwark) { create(:local_authority, :southwark) }

  before do
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss", local_authority:)
    create(:api_user, name: "other", token: "pUYptBJDVFzssbRPkCPjaZEx", local_authority: southwark)
    create(:application_type, :ldc_existing)
    create(:application_type, :ldc_proposed)
    create(:application_type, :pa_part_14_class_j)
    create(:application_type, :householder)
    create(:application_type, :householder_retrospective)
  end

  let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
  let(:planning_application) { example_fixture("validPlanningPermission.json") }
  let(:send_email) { "true" }

  let!(:planning_applications) { create_list(:planning_application, 8, local_authority: local_authority) }
  let!(:determined_planning_applications) { create_list(:planning_application, 3, :determined, local_authority: local_authority) }
  let(:page) { 2 }
  let(:maxresults) { 5 }
  let("ids[]") { [] }

  path "/api/v2/planning_applications" do
    post "Creates a new plannning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :planning_application, in: :body, schema: {
        "$ref": "#/components/schemas/Submission"
      }

      parameter name: :send_email, in: :query, schema: {
        enum: %w[true false],
        default: "true"
      }

      [
        %w[validLawfulDevelopmentCertificateExisting.json LDCE],
        %w[validLawfulDevelopmentCertificateProposed.json LDCP],
        %w[validPlanningPermission.json HAPP],
        %w[validPriorApproval.json PA14J],
        %w[validRetrospectivePlanningPermission.json HRET]
      ].each do |fixture, suffix|
        value = example_fixture(fixture, symbolize_names: true)
        name = value.dig(:data, :application, :type, :value)
        summary = value.dig(:data, :application, :type, :description)

        request_body_example(value:, name:, summary:)

        response "200", "with a valid request" do
          schema "$ref" => "#/components/schemas/SubmissionResponse"

          example "application/json", summary, {
            id: "BUC-23-00100-#{suffix}",
            message: "Application successfully created"
          }

          let(:planning_application) { example_fixture(fixture) }

          run_test!
        end
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

        let(:planning_application) do
          {
            "metadata" => {
              "schema" => "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.3.0/schema.json"
            }
          }
        end

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

      response "401", "with a token from another api user" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer pUYptBJDVFzssbRPkCPjaZEx" }

        run_test!
      end

      response "403", "when the endpoint is disabled" do
        before do
          allow(BopsApi::Application::CreationService).to receive(:new).and_raise(BopsApi::Errors::NotPermittedError)
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
          allow(LocalAuthority).to receive(:find_by!).and_raise(exception)
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

  path "/api/v2/planning_applications" do
    get "Retrieves planning applications" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }

      parameter name: "ids[]", in: :query, schema: {
        type: :array,
        items: {
          type: :integer
        }
      }

      response "200", "returns planning applications" do
        example "application/json", :default, api_json_fixture("planning_applications/index.json")

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 2,
              "results" => 5,
              "from" => 6,
              "to" => 10,
              "total_pages" => 3,
              "total_results" => 11
            }
          )
        end
      end

      response "200", "returns planning applications with given ids" do
        example "application/json", :ids, api_json_fixture("planning_applications/index.json")

        let(:page) { 1 }
        let("ids[]") { planning_applications.take(4).map(&:id) }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 4,
              "total_pages" => 1,
              "total_results" => 4
            }
          )
        end
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

      response "500", "when an internal server error occurs" do
        schema "$ref" => "#/components/schemas/InternalServerError"

        example "application/json", :default, {
          error: {
            code: 500,
            message: "Internal Server Error",
            detail: "expected :page in 1..3; got 4"
          }
        }

        let(:page) { 4 }

        run_test!
      end
    end
  end

  path "/api/v2/planning_applications/determined" do
    get "Retrieves determined planning applications" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }

      parameter name: "ids[]", in: :query, style: :form, explode: true, schema: {
        type: :array,
        items: {
          type: :integer
        }
      }

      response "200", "returns determined planning applications" do
        example "application/json", :default, api_json_fixture("planning_applications/determined.json")

        let(:page) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 3,
              "total_pages" => 1,
              "total_results" => 3
            }
          )

          statuses = data["data"].pluck("status").uniq
          expect(statuses).to eq(["determined"])
        end
      end

      response "200", "returns determined planning applications with given ids" do
        example "application/json", :ids, api_json_fixture("planning_applications/determined.json")

        let(:page) { 1 }
        let("ids[]") { determined_planning_applications[0, 2].map(&:id) }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 2,
              "total_pages" => 1,
              "total_results" => 2
            }
          )
        end
      end

      response "500", "when an internal server error occurs" do
        schema "$ref" => "#/components/schemas/InternalServerError"

        example "application/json", :default, {
          error: {
            code: 500,
            message: "Internal Server Error",
            detail: "expected :page in 1..8; got 20"
          }
        }

        run_test!
      end
    end
  end

  path "/api/v2/planning_applications/{id}" do
    get "Retrieves a planning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :id, in: :path, schema: {
        type: :integer,
        description: "The planning application ID"
      }

      response "200", "returns a planning application" do
        example "application/json", :default, api_json_fixture("planning_applications/show.json")

        let(:planning_application) { planning_applications.first }
        let(:id) { planning_application.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(id)
          expect(data["description"]).to eq(planning_application.description)
        end
      end

      response "404", "when no planning application can be found" do
        schema "$ref" => "#/components/schemas/NotFoundError"

        example "application/json", :default, {
          error: {
            code: 404,
            message: "Not Found",
            detail: "Couldn't find PlanningApplication with 'id'=734837"
          }
        }

        let(:id) { 734837 }

        run_test!
      end
    end
  end
end
