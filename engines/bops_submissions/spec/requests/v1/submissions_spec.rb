require "swagger_helper"

RSpec.describe "BOPS Submissions API", type: :request, swagger_doc: "swagger/v1/submissions.yaml" do
  path "/api/v1/submissions" do
    post "Creates a submission record" do
      tags "Submissions"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]
      parameter name: "Authorization", in: :header, type: :string, required: true
      parameter name: :event, in: :body, schema: { "$ref" => "#/definitions/SubmissionEvent" }

      response "202", "submission accepted" do
        let(:Authorization) { "Bearer #{ENV['API_TOKEN']}" }
        let(:event) do
          {
            applicationRef: "10087984",
            applicationVersion: 1,
            applicationState: "Submitted",
            sentDateTime: "2023-06-19T08:45:59.9722472Z",
            documentLinks: [
              {
                documentName: "PT-10087984.zip",
                documentLink: "https://example.com/files/PT-10087984.zip",
                expiryDateTime: "2023-07-19T08:45:59.975412Z",
                documentType: "application/x-zip-compressed"
              }
            ],
            updated: false
          }
        end

        before do
          stub_request(:get, event[:documentLinks].first[:documentLink])
            .to_return(
              status: 200,
              body: file_fixture("PT-10087984.zip").read,
              headers: { "Content-Type" => "application/zip" }
            )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to match(/[0-9a-f\-]{36}/)
        end
      end

      response "422", "invalid state" do
        let(:Authorization) { "Bearer #{ENV["API_TOKEN"]}" }
        let(:event) { { applicationRef: "100", applicationVersion: 1, applicationState: "Foo" } }
        run_test!
      end
    end
  end
end
