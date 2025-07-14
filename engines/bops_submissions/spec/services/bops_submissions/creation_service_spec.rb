# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::CreationService, type: :service do
  let(:local_authority) { create(:local_authority) }
  let(:submission_params_hash) do
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
  let(:params) { ActionController::Parameters.new(submission_params_hash) }
  let(:headers) do
    ActionDispatch::Request.new(
      "HTTP_USER_AGENT" => "Mozilla/5.0",
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_REQUEST_ID" => "abc-123"
    )
  end

  subject(:service) { described_class.new(params:, headers:, local_authority:) }

  it "creates a submission with filtered headers and permitted params" do
    expect {
      submission = service.call
      expect(submission.request_headers).to include(
        "User-Agent" => "Mozilla/5.0", "Content-Type" => "application/json", "X-Request-Id" => "abc-123"
      )
      expect(submission.request_body.deep_symbolize_keys).to eq(submission_params_hash)
      expect(submission.external_uuid).to match(/[0-9a-f\-]{36}/)
    }.to change { local_authority.submissions.count }.by(1)
  end

  it "filters only allowed headers" do
    headers.env["Authorization"] = "xxxxxx"
    submission = service.call
    expect(submission.request_headers).not_to have_key("Authorization")
  end
end
