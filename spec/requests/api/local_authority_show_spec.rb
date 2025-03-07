# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to show a local authority" do
  let(:reviewer) { create(:user, :reviewer) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority, decision: "granted")
  end
  let!(:lambeth) { create(:local_authority, :lambeth) }
  let!(:planning_application_lambeth) { create(:planning_application, :not_started, local_authority: lambeth) }

  describe "format" do
    let(:access_control_allow_origin) { response.headers["Access-Control-Allow-Origin"] }
    let(:access_control_allow_methods) { response.headers["Access-Control-Allow-Methods"] }
    let(:access_control_allow_headers) { response.headers["Access-Control-Allow-Headers"] }

    it "responds to JSON" do
      get "/api/v1/local_authorities/#{lambeth.subdomain}"

      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/api/v1/local_authorities/#{lambeth.subdomain}"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq("*")
      expect(access_control_allow_methods).to eq("*")
      expect(access_control_allow_headers).to eq("Origin, X-Requested-With, Content-Type, Accept")
    end
  end

  describe "data" do
    let(:local_authority_json) { json }

    it "returns a 404 if local authority not there" do
      get "/api/v1/local_authorities/xxx"
      expect(response.code).to eq("404")
      expect(local_authority_json).to eq({"message" => "Unable to find record"})
    end

    it "returns the accurate data" do
      get "/api/v1/local_authorities/#{lambeth.subdomain}"
      expect(local_authority_json["council_code"]).to eq("LBH")
      expect(local_authority_json["email_address"]).to eq("planning@lambeth.gov.uk")
    end
  end
end
