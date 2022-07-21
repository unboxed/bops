# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to patch document create requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:default_local_authority) { build(:local_authority, :default) }
  let(:user) { create(:user) }

  let!(:planning_application) do
    create(
      :planning_application,
      :invalidated,
      local_authority: default_local_authority,
      user: user
    )
  end

  let!(:additional_document_validation_request) do
    create(:additional_document_validation_request,
           planning_application: planning_application)
  end

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/additional_document_validation_requests/#{additional_document_validation_request.id}"
  end

  let(:file) do
    fixture_file_upload("../images/proposed-floorplan.png", "image/png")
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      files: [file]
    }
  end

  let(:headers) do
    { Authorization: "Bearer #{api_user.token}" }
  end

  it "successfully accepts a new document" do
    patch(path, params: params, headers: headers)

    expect(response).to be_successful

    additional_document_validation_request.reload
    planning_application.reload

    expect(additional_document_validation_request.state).to eq("closed")
    expect(additional_document_validation_request.documents.last).to be_a(Document)

    expect(Audit.all.last.activity_type).to eq("additional_document_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq("proposed-floorplan.png")
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "sends notification to assigned user" do
    expect { patch(path, params: params, headers: headers) }
      .to have_enqueued_job
      .on_queue("mailers")
      .with(
        "UserMailer",
        "update_notification_mail",
        "deliver_now",
        args: [planning_application, user.email]
      )
  end

  it "rejects wrong document types" do
    patch "/api/v1/planning_applications/#{planning_application.id}/additional_document_validation_requests/#{additional_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { files: [fixture_file_upload("../images/proposed-floorplan.png", "application/octet-stream")] },
          headers: { Authorization: "Bearer #{api_user.token}" }

    expect(response).not_to be_successful
    expect(json).to eq({ "message" => "The file type must be JPEG, PNG or PDF" })

    expect(additional_document_validation_request).to be_open
  end

  it "returns a 400 if the new document is missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/additional_document_validation_requests/#{additional_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { files: "" },
          headers: { Authorization: "Bearer #{api_user.token}" }

    expect(json).to eq({ "message" => "At least one file must be selected to proceed." })
    expect(response.status).to eq(400)
  end
end
