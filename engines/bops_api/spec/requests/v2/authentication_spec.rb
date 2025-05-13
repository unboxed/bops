# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "ApiUser" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:revoked_at) { nil }
  let(:api_user) { create(:api_user, local_authority:, revoked_at:) }

  let(:headers) do
    {
      "Authorization" => "Bearer #{api_user.token}"
    }
  end

  context "when the api key is revoked" do
    let(:revoked_at) { 1.hour.ago }

    it "does not permit access" do
      get "/api/v2/ping", headers:, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when an api request is made" do
    around do |example|
      freeze_time { example.run }
    end

    it "updates the last_used_at timestamp" do
      expect {
        get "/api/v2/ping", headers:, as: :json
      }.to change {
        api_user.reload.last_used_at
      }.from(nil).to(Time.current)
    end
  end
end
