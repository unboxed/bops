require "rails_helper"

RSpec.describe "API request to patch document create requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }

  let!(:additional_document_validation_request) do
    create(:additional_document_validation_request,
           planning_application: planning_application)
  end

  it "successfully accepts a new document" do
    patch "/api/v1/planning_applications/#{planning_application.id}/additional_document_validation_requests/#{additional_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: { new_file: fixture_file_upload("../images/proposed-floorplan.png") },
          headers: { "Authorization": "Bearer #{api_user.token}" }

    expect(response).to be_successful

    additional_document_validation_request.reload
    planning_application.reload

    expect(additional_document_validation_request.state).to eq("closed")
    expect(additional_document_validation_request.new_document).to be_a(Document)

    expect(Audit.all.last.activity_type).to eq("additional_document_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq("proposed-floorplan.png")
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "returns a 400 if the new document is missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/additional_document_validation_requests/#{additional_document_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: "{}",
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end
end
