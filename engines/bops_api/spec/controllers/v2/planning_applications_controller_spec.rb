# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::V2::PlanningApplicationsController, type: :controller do
  let(:examples_root) { BopsApi::Engine.root.join("spec", "fixtures", "examples", "odp") }
  let(:southwark) { create(:local_authority, :southwark) }
  let(:creation_service) { instance_double(BopsApi::Application::CreationService) }
  let(:planning_application) { instance_double(PlanningApplication) }

  routes { BopsApi::Engine.routes }

  before do
    token = "bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ"
    create(:api_user, token:, local_authority: southwark)

    request.set_header("HTTP_HOST", "southwark.bops.test")
    request.set_header("HTTP_AUTHORIZATION", "Bearer #{token}")

    request.set_header("bops.local_authority", southwark)
    request.set_header("bops.user_scope", southwark.users.kept)

    expect(BopsApi::Application::CreationService).to receive(:new).and_return(creation_service)
    expect(creation_service).to receive(:call!).and_return(planning_application)
  end

  %w[v0.2.1 v0.2.2 v0.2.3 v0.3.0 v0.4.0 v0.4.1 v0.5.0].each do |version|
    describe "ODP Schema #{version}" do
      %w[
        validLawfulDevelopmentCertificateExisting.json
        validLawfulDevelopmentCertificateProposed.json
        validPlanningPermission.json
        validPriorApproval.json
        validRetrospectivePlanningPermission.json
      ].each do |example|
        it "#{example} can be submitted successfully" do
          post :create, as: :json, body: examples_root.join(version, example).read

          expect(response).to have_http_status(:ok)
          expect(response).to render_template("bops_api/v2/planning_applications/create")
        end
      end
    end
  end

  %w[v0.6.0 v0.7.0].each do |version|
    describe "ODP Schema #{version}" do
      %w[
        validLawfulDevelopmentCertificateExisting.json
        validLawfulDevelopmentCertificateProposed.json
        validListedBuildingConsent.json
        validPlanningPermission.json
        validPriorApproval.json
        validRetrospectivePlanningPermission.json
      ].each do |example|
        it "#{example} can be submitted successfully" do
          post :create, as: :json, body: examples_root.join(version, example).read

          expect(response).to have_http_status(:ok)
          expect(response).to render_template("bops_api/v2/planning_applications/create")
        end
      end
    end
  end

  %w[v0.7.1 v0.7.2].each do |version|
    describe "ODP Schema #{version}" do
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
        it "#{example} can be submitted successfully" do
          post :create, as: :json, body: examples_root.join(version, example).read

          expect(response).to have_http_status(:ok)
          expect(response).to render_template("bops_api/v2/planning_applications/create")
        end
      end
    end
  end
end
