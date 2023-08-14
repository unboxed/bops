# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a planning application via the API", show_exceptions: true do
  let!(:api_user) { create(:api_user) }
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, local_authority:) }
  let!(:consultation) { create(:consultation, planning_application:) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/neighbour_responses"
  end

  let(:headers) do
    { "CONTENT-TYPE": "application/json",
      Authorization: "Bearer #{api_user.token}" }
  end

  it "successfully creates a new neighbour response" do
    json = '{
             "name": "Keira Walsh",
             "response": "This is good" }'

    post(path, params: json, headers:)

    expect(response).to be_successful
  end

  it "captures errors successfully" do
    json = '{
      "name": "",
      "response": "" }'

    post(path, params: json, headers:)

    expect(response).not_to be_successful
    expect(response).to have_http_status :bad_request
  end
end
