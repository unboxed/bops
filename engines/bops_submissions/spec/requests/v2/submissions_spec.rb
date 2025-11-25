# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "BOPS Submissions API", type: :request do
  let(:local_authority) { create(:local_authority, :default) }
  let(:valid_planning_portal_submission_event) { json_fixture_submissions("planning_portal.json") }
  let(:valid_enforcement_submission_event) { json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json") }
  let(:valid_enforcement_with_documents_submission_event) { json_fixture_api("examples/odp/v0.7.5/enforcement/breachWithDocuments.json") }
  let(:valid_planx_submission_event) { json_fixture_api("examples/odp/v0.7.5/application/planningPermission/fullHouseholder.json") }
  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }

  before do
    create(:api_user, permissions: %w[planning_application:write], token:, local_authority:)
  end

  path "/api/v2/submissions" do
    post "Creates a submission record" do
      tags "Submissions"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]

      parameter name: :event, in: :body, schema: {"$ref" => "#/components/schemas/SubmissionEvent"}
      parameter name: :schema, in: :query, enum: ["odp", "planning-portal"], required: false, default: "odp"

      request_body_example(
        name: "ValidPlanningPortalSubmissionEvent",
        summary: "Planning Portal Submission",
        value: json_fixture_submissions("planning_portal.json")
      )

      request_body_example(
        name: "ValidPlanXSubmissionEvent",
        summary: "PlanX Submission",
        value: json_fixture_api("examples/odp/v0.7.5/application/planningPermission/fullHouseholder.json")
      )

      request_body_example(
        name: "ValidEnforcementSubmissionEvent",
        summary: "Enforcement Submission",
        value: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
      )

      request_body_example(
        name: "ValidEnforcementWithDocumentsSubmissionEvent",
        summary: "Enforcement Submission with Documents",
        value: json_fixture_api("examples/odp/v0.7.5/enforcement/breachWithDocuments.json")
      )

      response "200", "submission accepted" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        let(:Authorization) { "Bearer #{token}" }

        context "for planning portal" do
          let(:schema) { "planning-portal" }
          let(:event) { valid_planning_portal_submission_event }

          before do
            stub_request(:get, event["documentLinks"].first["documentLink"])
              .to_return(
                status: 200,
                body: file_fixture_submissions("applications/PT-10087984.zip"),
                headers: {"Content-Type" => "application/zip"}
              )
          end

          run_test! do |response|
            body = JSON.parse(response.body)
            expect(body["uuid"]).to match(/[0-9a-f-]{36}/)
          end
        end

        context "for odp" do
          context "for planning applications" do
            let(:event) { valid_planx_submission_event }
            run_test! do |response|
              body = JSON.parse(response.body)
              expect(body["uuid"]).to match(/[0-9a-f-]{36}/)
            end
          end

          context "for enforcements" do
            let(:event) { valid_enforcement_submission_event }
            run_test! do |response|
              body = JSON.parse(response.body)
              expect(body["uuid"]).to match(/[0-9a-f-]{36}/)
            end
          end

          context "for enforcements with documents" do
            let(:event) { valid_enforcement_with_documents_submission_event }
            run_test! do |response|
              body = JSON.parse(response.body)
              expect(body["uuid"]).to match(/[0-9a-f-]{36}/)
            end
          end
        end
      end

      response "400", "bad request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        let(:Authorization) { "Bearer #{token}" }
        let(:event) { {foo: "bar"} }
        let(:schema) { "planning-portal" }

        let(:creation_service) { instance_double(BopsSubmissions::CreationService) }

        before do
          allow(BopsSubmissions::CreationService).to receive(:new).and_return(creation_service)
          allow(creation_service).to receive(:call).and_raise(ActionController::BadRequest)
        end

        run_test!
      end

      response "401", "missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { nil }
        let(:event) { valid_planning_portal_submission_event }
        let(:schema) { "planning-portal" }

        run_test!
      end

      response "422", "missing request body" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        let(:Authorization) { "Bearer #{token}" }
        let(:event) { nil }
        let(:schema) { "planning-portal" }

        run_test!
      end
    end
  end

  path "/api/v2/submissions/{sqid}" do
    post "Creates a submission record" do
      tags "Submissions"
      consumes "application/json"
      produces "application/json"
      security [terraquestAuth: []]

      parameter name: "sqid", in: :path, required: true
      parameter name: "tq-timestamp", in: :header, required: true, getter: "timestamp"

      parameter name: :event, in: :body, schema: {"$ref" => "#/components/schemas/SubmissionEvent"}
      parameter name: :schema, in: :query, enum: ["planning-portal"], required: true, default: "planning-portal"

      request_body_example(
        name: "ValidPlanningPortalSubmissionEvent",
        summary: "Planning Portal Submission",
        value: json_fixture_submissions("planning_portal.json")
      )

      response "200", "submission accepted" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        let(:api_user) { create(:api_user, :planning_portal) }
        let(:sqid) { api_user.sqid }

        let(:timestamp) { "2025-11-25T12:00:00Z" }
        let(:Authorization) { api_user.hmac_signature("2025-11-25T12:00:00Z") }

        let(:schema) { "planning-portal" }
        let(:event) { valid_planning_portal_submission_event }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["uuid"]).to match(/[0-9a-f-]{36}/)
        end
      end

      response "400", "bad request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        let(:api_user) { create(:api_user, :planning_portal) }
        let(:sqid) { api_user.sqid }

        let(:timestamp) { "2025-11-25T12:00:00Z" }
        let(:Authorization) { api_user.hmac_signature("2025-11-25T12:00:00Z") }

        let(:schema) { "planning-portal" }
        let(:event) { {foo: "bar"} }

        let(:creation_service) { instance_double(BopsSubmissions::CreationService) }

        before do
          allow(BopsSubmissions::CreationService).to receive(:new).and_return(creation_service)
          allow(creation_service).to receive(:call).and_raise(ActionController::BadRequest)
        end

        run_test!
      end

      response "401", "missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:api_user) { create(:api_user, :planning_portal) }
        let(:sqid) { api_user.sqid }

        let(:timestamp) { "2025-11-25T12:00:00Z" }
        let(:Authorization) { api_user.hmac_signature("2025-11-25T12:00:00Z") }

        let(:schema) { "planning-portal" }
        let(:event) { valid_planning_portal_submission_event }

        context "when sqid is incorrect" do
          let(:sqid) { "123" }

          run_test!
        end

        context "when HMAC signature is incorrect" do
          let(:Authorization) { "notasignature" }

          run_test!
        end

        context "when timestamp is incorrect" do
          let(:timestamp) { "2025-11-25T13:00:00Z" }

          run_test!
        end
      end

      response "422", "missing request body" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        let(:api_user) { create(:api_user, :planning_portal) }
        let(:sqid) { api_user.sqid }

        let(:timestamp) { "2025-11-25T12:00:00Z" }
        let(:Authorization) { api_user.hmac_signature("2025-11-25T12:00:00Z") }

        let(:schema) { "planning-portal" }
        let(:event) { nil }

        run_test!
      end
    end
  end
end
