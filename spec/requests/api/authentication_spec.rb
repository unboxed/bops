# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ApiUser" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:revoked_at) { nil }
  let(:api_user) { create(:api_user, local_authority:, revoked_at:) }

  context "when the api key is revoked" do
    let(:revoked_at) { Time.zone.now }

    it "does not permit access" do
      get("/api/v2/planning_applications", headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"})
      expect(response.status).to eq 401
    end
  end
end
