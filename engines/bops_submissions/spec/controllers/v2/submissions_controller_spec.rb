# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::V2::SubmissionsController, type: :controller do
  let(:local_authority) { create(:local_authority, :southwark) }
  let(:version) { "v0.7.5" }

  routes { BopsSubmissions::Engine.routes }

  before do
    token = "bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ"
    create(:api_user, permissions: %w[planning_application:write], token:, local_authority:)

    request.set_header("HTTP_HOST", "#{local_authority}.bops.test")
    request.set_header("HTTP_AUTHORIZATION", "Bearer #{token}")

    request.set_header("bops.local_authority", local_authority)
    request.set_header("bops.user_scope", local_authority.users.kept)
  end

  context "when submitting a planning application from planx" do
    let(:creation_service) { instance_double(BopsSubmissions::Application::PlanxCreationService) }
    let(:planning_application) { instance_double(PlanningApplication) }

    before do
      expect(BopsSubmissions::Application::PlanxCreationService).to receive(:new).and_return(creation_service)
      expect(BopsApi::Application::CreationService).not_to receive(:new)
      expect(BopsSubmissions::Application::PlanningPortalCreationService).not_to receive(:new)
      expect(BopsSubmissions::Enforcement::CreationService).not_to receive(:new)

      expect(creation_service).to receive(:call!).and_return(planning_application)
    end

    %w[
      application/landDrainageConsent.json
      application/lawfulDevelopmentCertificate/existing.json
      application/lawfulDevelopmentCertificate/proposed.json
      application/listedBuildingConsent.json
      application/planningPermission/fullHouseholder.json
      application/planningPermission/fullHouseholderInConservationArea.json
      application/planningPermission/major.json
      application/planningPermission/minor.json
      application/priorApproval/buildHomes.json
      application/priorApproval/convertCommercialToHome.json
      application/priorApproval/extendUniversity.json
      application/priorApproval/largerExtension.json
      application/priorApproval/solarPanels.json
      preApplication/preApp.json
    ].each do |example|
      it "#{example} can be submitted" do
        post :create, as: :json, body: json_fixture_api("examples/odp/#{version}/#{example}").to_json

        perform_enqueued_jobs

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("bops_submissions/v2/submissions/create")
      end
    end
  end

  context "when submitting a planning application from planning portal" do
    let(:planning_application) { instance_double(PlanningApplication) }
    let(:json_data) { json_fixture_submissions("planning_portal.json") }

    before do
      expect(BopsApi::Application::CreationService).not_to receive(:new)
      expect(BopsSubmissions::Enforcement::CreationService).not_to receive(:new)

      stub_request(:get, json_data["documentLinks"].first["documentLink"])
        .to_return(
          status: 200,
          body: file_fixture_submissions("applications/PT-10087984.zip"),
          headers: {"Content-Type" => "application/zip"}
        )
    end

    context "with a valid schema parameter" do
      let(:body) { json_data.merge(schema: "planning-portal") }
      let(:creation_service) { instance_double(BopsSubmissions::Application::PlanningPortalCreationService) }

      before do
        expect(BopsSubmissions::Application::PlanningPortalCreationService).to receive(:new).and_return(creation_service)
        expect(creation_service).to receive(:call!).and_return(planning_application)
      end

      it "planning_portal.json can be submitted" do
        post :create, as: :json, body: body.to_json

        perform_enqueued_jobs

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("bops_submissions/v2/submissions/create")
      end
    end

    context "without the correct schema parameter" do
      before do
        expect(BopsSubmissions::Application::PlanningPortalCreationService).not_to receive(:new)
      end

      it "planning_portal.json fails without schema parameter" do
        post :create, as: :json, body: json_data.to_json

        expect {
          perform_enqueued_jobs
        }.not_to change(Submission, :count)

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  context "when submitting an enforcement" do
    let(:creation_service) { instance_double(BopsSubmissions::Enforcement::CreationService) }
    let(:enforcement) { instance_double(Enforcement) }

    before do
      expect(BopsApi::Application::CreationService).not_to receive(:new)
      expect(BopsSubmissions::Application::PlanningPortalCreationService).not_to receive(:new)
      expect(BopsSubmissions::Enforcement::CreationService).to receive(:new).and_return(creation_service)
      expect(creation_service).to receive(:call!).and_return(enforcement)
    end

    it "enforcement/breach.json can be submitted" do
      post :create, as: :json, body: json_fixture_api("examples/odp/#{version}/enforcement/breach.json").to_json

      perform_enqueued_jobs

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("bops_submissions/v2/submissions/create")
    end
  end
end
