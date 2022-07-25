# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to patch document validation requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user) }

  let!(:planning_application) do
    create(
      :planning_application,
      :invalidated,
      user: user,
      local_authority: default_local_authority
    )
  end

  let!(:document) do
    create(:document, :with_file, :public, planning_application: planning_application, validated: false,
                                           invalidated_document_reason: "Not readable")
  end

  let!(:replacement_document_validation_request) do
    create(:replacement_document_validation_request,
           planning_application: planning_application,
           old_document: document)
  end

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
  end

  let(:file) do
    fixture_file_upload("../images/proposed-floorplan.png", "image/png")
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      new_file: file
    }
  end

  let(:headers) do
    { Authorization: "Bearer #{api_user.token}" }
  end

  it "successfully accepts a new document and archives the old document" do
    patch(path, params: params, headers: headers)

    expect(response).to be_successful

    replacement_document_validation_request.reload
    planning_application.reload
    document.reload

    expect(replacement_document_validation_request.state).to eq("closed")
    expect(replacement_document_validation_request.new_document).to be_a(Document)
    expect(document.archived_at).not_to eq(nil)
    expect(document.archive_reason).to eq("Applicant has provived a replacement document.")

    expect(Audit.all.last.activity_type).to eq("replacement_document_validation_request_received")
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
    patch "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { new_file: fixture_file_upload("../images/proposed-floorplan.png", "image/bmp") },
          headers: { Authorization: "Bearer #{api_user.token}" }

    expect(response).not_to be_successful

    expect(replacement_document_validation_request).to be_open
  end

  it "returns a 400 if the new document is missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: "{}",
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end

  it "returns a 400 if the file size exceeds 30mb" do
    # Return byte size greater than limit of 30mb (31457280 bytes)
    allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(31_457_281)

    patch "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { new_file: file },
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(json).to eq({ "message" => "The file must be 30MB or less" })
    expect(response.status).to eq(400)
  end
end
