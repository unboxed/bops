# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "BOPS Submissions API", type: :request do
  let(:local_authority) { create(:local_authority, :default) }
  let(:valid_submission_event) { json_fixture_submissions("planning_portal.json") }

  before do
    create(:api_user, permissions: %w[planning_application:write], token: "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw", local_authority:)
  end

  path "/api/v2/submissions" do
    post "Creates a submission record" do
      tags "Submissions"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]

      parameter name: :event, in: :body, schema: {
        "$ref" => "#/components/schemas/SubmissionEvent"
      }

      request_body_example(
        name: "ValidPlanningPortalSubmissionEvent",
        summary: "Planning Portal Submission",
        value: json_fixture_submissions("planning_portal.json")
      )

      request_body_example(
        name: "ValidEnforcementSubmissionEvent",
        summary: "Enforcement Submission",
        value: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
      )

      response "200", "submission accepted" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
        let(:event) { valid_submission_event }

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
          expect(body["uuid"]).to match(/[0-9a-f\-]{36}/)
        end
      end

      response "401", "missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { nil }
        let(:event) { valid_submission_event }

        run_test!
      end

      response "422", "missing request body" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
        let(:event) { nil }

        run_test!
      end

      response "400", "bad request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
        let(:event) { {foo: "bar"} }

        before do
          allow_any_instance_of(BopsSubmissions::V2::SubmissionsController)
            .to receive(:create) do |controller|
              controller.response.status = 400
              controller.response_body = [{error: {code: 400, message: "Bad Request", detail: "Bad request error"}}.to_json]
            end
        end

        run_test!
      end
    end
  end
end
