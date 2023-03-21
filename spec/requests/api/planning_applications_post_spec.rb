# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a planning application via the API", show_exceptions: true do
  let!(:api_user) { create(:api_user) }

  before { create(:local_authority, :default) }

  def post_with(params:, headers: {})
    post(
      "/api/v1/planning_applications",
      params:,
      headers: {
        "CONTENT-TYPE": "application/json",
        Authorization: "Bearer #{api_user.token}"
      }.merge(headers)
    )
  end

  context "with success in downloading document" do
    before do
      stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(
          status: 200,
          body: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").read,
          headers: { "Content-Type" => "application/pdf" }
        )
    end

    context "when passed a request with invalid parameters" do
      json = '{
             "id": "e4c94a81-4169-42df-8ad0-32c4690f4005",
             "reference": "20/AP/2161",
             "related_cases": "20/AP/0135"}'

      it "returns a 400 response" do
        post_with(params: json)

        expect(response).to have_http_status(:bad_request)
      end

      it "returns 401 if user is not authenticated" do
        post_with(params: json, headers: { Authorization: "Bearer dasfdsafdsaf" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "renders failure message" do
        post "/api/v1/planning_applications", params: json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(response.body).to eq("{\"message\":\"Validation failed: Application type can't be blank, An applicant or agent email is required.\"}")
      end
    end

    context "when passed a request with valid but not used parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/valid_planning_application.json")
      permitted_development_json = File.read(valid_json)

      it "saves a valid planning application" do
        post_with(params: permitted_development_json)

        expect(response).to have_http_status :ok

        planning_application = PlanningApplication.last
        expect(planning_application).to be_valid
        expect(JSON.parse(planning_application.planx_data)).to be_a(Hash)
      end

      it "saves the feedback as a hash" do
        post_with(params: permitted_development_json)

        expect(PlanningApplication.last.feedback).to eq(
          {
            "result" => "feedback about the result",
            "find_property" => "feedback about the property",
            "planning_constraints" => "feedback about the constraints"
          }
        )
      end

      it "sends the receipt email" do
        post_with(params: permitted_development_json)
        perform_enqueued_jobs

        email = ActionMailer::Base.deliveries.last
        expect(email.body).to include(PlanningApplication.all[0].reference)
        expect(email.body).to include("We’ve received your application for a Lawful Development Certificate.")
      end

      it "downloads and saves the plan against the planning application" do
        post "/api/v1/planning_applications", params: permitted_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(PlanningApplication.last.documents.first.file).to be_present
      end

      it "returns a 200 response" do
        post "/api/v1/planning_applications", params: permitted_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(response).to have_http_status(:ok)
      end

      it "renders success message" do
        post "/api/v1/planning_applications", params: permitted_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(response.body).to eq({ id: PlanningApplication.all[0].reference.to_s,
                                      message: "Application created" }.to_json)
      end

      it "returns 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: permitted_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer dasfdsafdsaf" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when passed a request with the minimal parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/minimal_planning_application.json")
      minimal_development_json = File.read(valid_json)

      it "saves a valid planning application" do
        post "/api/v1/planning_applications", params: minimal_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(PlanningApplication.all[0]).to be_valid
      end

      it "returns a 200 response" do
        post "/api/v1/planning_applications", params: minimal_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(response).to have_http_status(:ok)
      end

      it "renders success message" do
        post "/api/v1/planning_applications", params: minimal_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }
        expect(response.body).to eq({ id: PlanningApplication.all[0].reference.to_s,
                                      message: "Application created" }.to_json)
      end

      it "returns 401 if user is not authenticated" do
        post "/api/v1/planning_applications", params: minimal_development_json,
                                              headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer dasfdsafdsaf" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 if no authorization is supplied" do
        post "/api/v1/planning_applications", params: minimal_development_json,
                                              headers: { "CONTENT-TYPE": "application/json" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq('{"error":"HTTP Token: Access denied."}')
      end
    end
  end

  context "with error in downloading document" do
    before do
      stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(status: 404, body: "")
    end

    context "when passed a request with the minimal parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/valid_planning_application.json")
      minimal_development_json = File.read(valid_json)

      it "raises an error" do
        post_with(params: minimal_development_json)

        expect(response).to have_http_status :bad_request
        expect(response.body).to eq(
          "{\"message\":\"The document: 'proposed-first-floor-plan.pdf' at location: 'https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf' does not exist or is forbidden\"}"
        )
      end
    end
  end

  context "with the wrong type of document" do
    before do
      stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(status: 200, body: "some document", headers: { "Content-Type" => "application/octet-stream" })
    end

    context "when passed a request with the minimal parameters" do
      valid_json = Rails.root.join("spec/fixtures/files/valid_planning_application.json")
      minimal_development_json = File.read(valid_json)

      it "rejects the application" do
        post_with(params: minimal_development_json)

        expect(response).to have_http_status :bad_request
        expect(response.body).to eq('{"message":"The document \"proposed-first-floor-plan.pdf\" doesn\'t match our accepted file types"}')
      end

      it "does not persist the application" do
        expect { post_with(params: minimal_development_json) }.not_to change(PlanningApplication, :count)
      end
    end
  end
end
