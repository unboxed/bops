# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /healthcheck" do
  let!(:local_authority) { create(:local_authority, :default) }

  shared_examples "a healthcheck response" do
    it "returns 200 OK" do
      get "/healthcheck"
      expect(response).to have_http_status(:ok)
    end
  end

  context "when on the config subdomain" do
    before do
      host! "config.example.com"
    end

    it_behaves_like "a healthcheck response"
  end

  context "when on a local authority subdomain" do
    before do
      host! "default.example.com"
    end

    it_behaves_like "a healthcheck response"
  end

  context "when on an internal hostname" do
    before do
      host! "ip-192-168-0-1.example.internal"
    end

    it_behaves_like "a healthcheck response"
  end
end
