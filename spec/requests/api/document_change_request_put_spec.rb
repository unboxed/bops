require "rails_helper"

RSpec.describe "API request to patch document change requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }
  let!(:document) { create(:document, :with_file, :public, planning_application: planning_application, validated: false, invalidated_document_reason: "Not readable") }

  let!(:replacement_document_validation_request) do
    create(:replacement_document_validation_request,
           planning_application: planning_application,
           old_document: document)
  end

  it "successfully accepts a new document and archives the old document" do
    patch "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { new_file: fixture_file_upload("../images/proposed-floorplan.png") },
          headers: { "Authorization": "Bearer #{api_user.token}" }

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

  it "returns a 400 if the new document is missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: "{}",
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end
end
