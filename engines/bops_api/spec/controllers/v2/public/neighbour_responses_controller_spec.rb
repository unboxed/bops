# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::V2::Public::NeighbourResponsesController, type: :controller do
  routes { BopsApi::Engine.routes }
  render_views

  let(:southwark) { create(:local_authority, :southwark) }
  let(:planning_application) { create(:planning_application, :published, :in_assessment, :with_boundary_geojson, :planning_permission, local_authority: southwark) }
  let(:consultation) { planning_application.consultation }

  before do
    request.set_header("HTTP_HOST", "southwark.bops.test")
    request.set_header("bops.local_authority", southwark)

    allow_any_instance_of(BopsApi::V2::Public::NeighbourResponsesController)
      .to receive(:find_planning_application)
      .and_return(planning_application)

    # Create a neighbour response for each sentiment
    NeighbourResponse.summary_tags.keys.each do |sentiment|
      neighbour = create(:neighbour, consultation: consultation)
      create(:neighbour_response, summary_tag: NeighbourResponse.summary_tags.keys.sample, neighbour: neighbour)
    end
  end

  describe "GET #index" do
    it "returns a successful response and expected json keys" do
      get :index, params: {planning_application_id: planning_application.reference}, format: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["pagination"]).to eq({"resultsPerPage" => 10, "currentPage" => 1, "totalPages" => 1, "totalResults" => 3, "totalAvailableItems" => 3})
      expect(json["comments"].size).to eq(3)
    end
  end

  describe "#pagination_params" do
    it "handles single sentiment values" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "supportive"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["supportive"])
    end

    it "handles comma-separated sentiment values" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "supportive,neutral"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["supportive", "neutral"])
    end

    it "handles comma-separated sentiment values with duplicates" do
      get :index, params: {planning_application_id: planning_application.reference, sentiment: "supportive,neutral,supportive"}, format: :json
      controller_params = controller.send(:pagination_params)
      expect(controller_params[:sentiment]).to eq(["supportive", "neutral"])
    end
  end
end
