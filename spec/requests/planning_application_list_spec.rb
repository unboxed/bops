# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "API request to list planning applications", type: :request, show_exceptions: true do
  let(:reviewer) { create :user, :reviewer }
  let(:api_user) { create :api_user }

  before do
    create(:decision, :granted, user: reviewer)
  end

  describe "format" do
    let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
    let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
    let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

    it "responds to JSON" do
      get "/api/v1/planning_applications"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/api/v1/planning_applications"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end
  end

  describe "data" do
    let(:data) { json["data"] }

    it "returns an empty response if no planning application" do
      get "/api/v1/planning_applications.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end

    it "returns a list of serialized planning application" do
      planning_application_1 = create(:planning_application, :determined)
      planning_application_2 = create(:planning_application, :determined)

      decision_granted = create(:decision, :granted, user: reviewer, planning_application: planning_application_1)
      decision_refused = create(:decision, :refused, user: reviewer, planning_application: planning_application_2)

      get "/api/v1/planning_applications.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "id" => planning_application_1.id,
            "application_number" => planning_application_1.reference,
            "site_address" => planning_application_1.site.full_address,
            "application_type" => "Certificate of Lawfulness",
            "summary_of_proposal" => planning_application_1.description,
            "received_date" => planning_application_1.created_at.getutc.iso8601,
            "determined_at" => planning_application_1.determined_at.getutc.iso8601,
            "status" => "granted"
          ),
          a_hash_including(
            "id" => planning_application_2.id,
            "application_number" => planning_application_2.reference,
            "site_address" => planning_application_2.site.full_address,
            "application_type" => "Certificate of Lawfulness",
            "summary_of_proposal" => planning_application_2.description,
            "received_date" => planning_application_2.created_at.getutc.iso8601,
            "determined_at" => planning_application_1.determined_at.getutc.iso8601,
            "status" => "refused"
          )
        )
      )
    end

    it "returns an empty response if the planning application is in assessment" do
      planning_application_1 = create(:planning_application)
      decision_granted = create(:decision, :granted, user: reviewer, planning_application: planning_application_1)

      get "/api/v1/planning_applications.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end

    it "returns an empty response if the planning application is in awaiting determination" do
      planning_application_1 = create(:planning_application, :awaiting_determination)
      decision_granted = create(:decision, :granted, user: reviewer, planning_application: planning_application_1)

      get "/api/v1/planning_applications.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end
  end
end
