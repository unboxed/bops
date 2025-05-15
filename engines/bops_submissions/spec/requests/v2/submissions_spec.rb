# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS Submissions API", type: :request do
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
        name: "ValidSubmissionEvent",
        summary: "Planning Portal Submission",
        value: {
          applicationRef: "10087984",
          applicationVersion: 1,
          applicationState: "Submitted",
          sentDateTime: "2023-06-19T08:45:59.9722472Z",
          updated: false,
          documentLinks: [
            {
              documentName: "PT-10087984.zip",
              documentLink: "https://example.com/files/PT-10087984.zip",
              expiryDateTime: "2023-07-19T08:45:59.975412Z",
              documentType: "application/x-zip-compressed"
            }
          ]
        }
      )

      response "202", "submission accepted" do
        schema "$ref" => "#/components/schemas/SubmissionResponse"

        let(:Authorization) { "Bearer #{ENV["API_TOKEN"]}" }
        let(:event) do
          {
            applicationRef: "10087984",
            applicationVersion: 1,
            applicationState: "Submitted",
            sentDateTime: "2023-06-19T08:45:59.9722472Z",
            updated: false,
            documentLinks: [
              {
                documentName: "PT-10087984.zip",
                documentLink: "https://example.com/files/PT-10087984.zip",
                expiryDateTime: "2023-07-19T08:45:59.975412Z",
                documentType: "application/x-zip-compressed"
              }
            ]
          }
        end

        before do
          stub_request(:get, event[:documentLinks].first[:documentLink])
            .to_return(
              status: 200,
              body: file_fixture("PT-10087984.zip").read,
              headers: {"Content-Type" => "application/zip"}
            )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to match(/[0-9a-f\-]{36}/)
        end
      end

      response "422", "invalid state" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        let(:Authorization) { "Bearer #{ENV["API_TOKEN"]}" }
        let(:event) { {applicationRef: "100", applicationVersion: 1, applicationState: "Foo"} }

        run_test!
      end
    end
  end
end
