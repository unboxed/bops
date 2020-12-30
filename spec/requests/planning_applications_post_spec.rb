# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::PlanningApplicationsController, type: :request, show_exceptions: true do
  let(:api_user) { create :api_user }

  context "with success in downloading document" do
    before do
      stub_request(:get, "https://bops-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf").
          to_return(status: 200, body: File.read(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")))
    end
    context "when passed a request with invalid parameters" do
      json = '{
             "id": "e4c94a81-4169-42df-8ad0-32c4690f4005",
             "reference": "20/AP/2161",
             "related_cases": "20/AP/0135"}'

      it "should return a 400 response" do
        post "/api/v1/planning_applications", params: json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.status).to eq(400)
      end

      it "should return 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer dasfdsafdsaf" }
        expect(response.status).to eq(401)
      end

      it "should render failure message" do
        post "/api/v1/planning_applications", params: json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.body).to eq('{"message":"Unable to create application"}')
      end
    end

    context "when passed a request with valid but not used parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/valid_planning_application.json")
      permitted_development_json = File.read(valid_json)

      it "saves a valid planning application" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(PlanningApplication.all[0]).to be_valid
      end

      it "downloads and saves the plan against the planning application" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(PlanningApplication.last.documents.first.plan).to be_present
      end

      it "returns a 200 response" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.status).to eq(200)
      end

      it "should render success message" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.body).to eq({ "id": "#{PlanningApplication.all[0].reference}",
                                      "message": "Application created" }.to_json)
      end

      it "should return 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer dasfdsafdsaf" }
        expect(response.status).to eq(401)
      end
    end

    context "when passed a request with the minimal parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/minimal_planning_application.json")
      minimal_development_json = File.read(valid_json)

      it "saves a valid planning application" do
        post "/api/v1/planning_applications", params: minimal_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(PlanningApplication.all[0]).to be_valid
      end

      it "returns a 200 response" do
        post "/api/v1/planning_applications", params: minimal_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.status).to eq(200)
      end

      it "should render success message" do
        post "/api/v1/planning_applications", params: minimal_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.body).to eq({ "id": "#{PlanningApplication.all[0].reference}",
                                      "message": "Application created" }.to_json)
      end

      it "should return 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: minimal_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer dasfdsafdsaf" }
        expect(response.status).to eq(401)
      end

      it "should return 401 if no authorization is supplied" do
        post "/api/v1/planning_applications", params: minimal_development_json,
             headers: { "CONTENT-TYPE": "application/json" }
        expect(response.status).to eq(401)
        expect(response.body).to eq('{"error":"HTTP Token: Access denied."}')
      end
    end

    context "when passed a request where site uprn exists" do
      valid_json = Rails.root.join("spec/fixtures/files/minimal_planning_application.json")
      permitted_development_json = File.read(valid_json)

      it "should render success message" do
        site_1 = create(:site, uprn: "100081043511")
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.body).to eq({ "id": "#{PlanningApplication.all[0].reference}",
                                      "message": "Application created" }.to_json)
      end

      it "should render sucess message" do
        site_1 = create(:site, uprn: "100081043511")
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        expect(response.status).to eq(200)
      end

      it "should return 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: permitted_development_json,
             headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer dasfdsafdsaf" }
        expect(response.status).to eq(401)
      end
    end
  end

  context "with error in downloading document" do
    before do
      stub_request(:get, "https://bops-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf").
          to_return(status: 404, body: "")
    end

    context "when passed a request with the minimal parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/valid_planning_application.json")
      minimal_development_json = File.read(valid_json)

      it "raises an error" do
        expect {
          post "/api/v1/planning_applications", params: minimal_development_json,
               headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
        }.to raise_error(OpenURI::HTTPError)
      end
    end
  end
end
