# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::V2::Public::ConsulteeResponsesController, type: :controller do
  routes { BopsApi::Engine.routes }
  render_views

  let(:southwark) { create(:local_authority, :southwark) }
  let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority: southwark) }
  let(:consultation) { planning_application.consultation }

  before do
    request.set_header("HTTP_HOST", "southwark.bops.test")
    request.set_header("bops.local_authority", southwark)

    allow_any_instance_of(BopsApi::V2::Public::ConsulteeResponsesController)
      .to receive(:find_planning_application)
      .and_return(planning_application)

    # create a consultee with a response for each sentiment
    Consultee::Response.summary_tags.keys.each do |sentiment|
      create(:consultee, :consulted, responses: build_list(:consultee_response, 1, :with_redaction, summary_tag: sentiment), consultation: planning_application.consultation)
    end
  end

  describe "GET #index" do
    context "when consultation exists" do
      it "returns a successful response and expected json keys" do
        get :index, params: {planning_application_id: planning_application.reference}, format: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["pagination"]).to eq({"resultsPerPage" => 10, "currentPage" => 1, "totalPages" => 1, "totalResults" => 3, "totalAvailableItems" => 3})
        expect(json.dig("data", "comments").size).to eq(3)
      end
    end

    context "when consultation is missing" do
      before do
        allow(planning_application).to receive(:consultation).and_return(nil)
      end

      it "returns an InvalidRequestError" do
        get :index, params: {planning_application_id: planning_application.reference}, format: :json
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]["message"]).to eq("Bad Request")
        expect(json["error"]["detail"]).to eq("Consultation not found")
      end
    end
  end

  describe "#pagination_params" do
    it "handles single sentiment values" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "approved"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["approved"])
    end

    it "handles comma-separated sentiment values" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "approved,objected"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["approved", "objected"])
    end

    it "handles comma-separated sentiment values with duplicates" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "approved,objected,approved"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["approved", "objected"])
    end
  end
end
