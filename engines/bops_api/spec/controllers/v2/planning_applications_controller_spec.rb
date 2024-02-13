# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::V2::PlanningApplicationsController, type: :controller do
  let(:examples_root) { BopsApi::Engine.root.join("spec", "fixtures", "examples") }
  let(:southwark) { create(:local_authority, :southwark) }
  let(:creation_service) { instance_double(BopsApi::Application::CreationService) }
  let(:planning_application) { instance_double(PlanningApplication) }

  routes { BopsApi::Engine.routes }

  before do
    create(:api_user, token: "pUYptBJDVFzssbRPkCPjaZEx", local_authority: southwark)

    request.set_header("HTTP_HOST", "southwark.bops.test")
    request.set_header("HTTP_AUTHORIZATION", "Bearer pUYptBJDVFzssbRPkCPjaZEx")

    expect(BopsApi::Application::CreationService).to receive(:new).and_return(creation_service)
    expect(creation_service).to receive(:call!).and_return(planning_application)
  end

  %w[v0.2.1 v0.2.2 v0.2.3 v0.3.0].each do |version|
    describe "ODP Schema #{version}" do
      %w[
        validLawfulDevelopmentCertificateExisting.json
        validLawfulDevelopmentCertificateProposed.json
        validPlanningPermission.json
        validPriorApproval.json
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
