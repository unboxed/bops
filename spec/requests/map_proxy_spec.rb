# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapProxyController, type: :request do
  let!(:local_authority) { create(:local_authority, subdomain: "lambeth", applicants_url: "https://lambeth.bops-applicants.services") }
  let(:tile_path) { "/map_proxy/maps/vector/v1/vts/tile/18/87234/131012.pbf" }
  let(:os_api_url) { "https://api.os.uk/maps/vector/v1/vts/tile/18/87234/131012.pbf" }
  let(:mock_response) do
    {
      status: 200,
      headers: {"Content-Type" => "application/octet-stream"},
      body: "mock tile data"
    }
  end

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"

    stub_request(:get, os_api_url)
      .with(
        headers: {
          "key" => Rails.configuration.os_vector_tiles_api_key,
          "Accept" => "application/octet-stream"
        }
      )
      .to_return(mock_response)
  end

  describe "GET /map_proxy/*path" do
    context "same-origin request" do
      it "returns tile data successfully" do
        host! "lambeth.bops.services"
        get tile_path

        expect(response).to have_http_status(:success)
        expect(response.body).to eq("mock tile data")

        expect(response.headers["Cross-Origin-Resource-Policy"]).to eq("cross-origin")
        expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
      end
    end

    context "cross-origin request from matching applicants_url" do
      it "returns tile data with correct CORS headers" do
        host! "lambeth.bops.services"
        get tile_path, headers: {"Origin" => "https://lambeth.bops-applicants.services"}

        expect(response).to have_http_status(:success)
        expect(response.body).to eq("mock tile data")
        expect(response.headers["Cross-Origin-Resource-Policy"]).to eq("cross-origin")
        expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://lambeth.bops-applicants.services")
      end
    end

    context "cross-origin request with mismatched origin" do
      it "denies access with 403" do
        host! "lambeth.bops.services"
        get tile_path, headers: {"Origin" => "https://fake.bops-applicants.services"}

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq("CORS policy: Origin not allowed")
      end
    end
  end
end
