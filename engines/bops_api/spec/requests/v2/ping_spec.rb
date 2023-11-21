# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BopsApi", type: :request do
  around do |example|
    travel_to("2023-11-21T18:30:00Z") { example.run }
  end

  let(:json) { JSON.parse(response.body) }

  describe "GET /api/v2/ping" do
    before do
      get "/api/v2/ping"
    end

    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON" do
      expect(response).to have_attributes(content_type: "application/json; charset=utf-8")
    end

    it "returns an 'OK' message" do
      expect(json).to match(a_hash_including("message" => "OK"))
    end

    it "returns the current time" do
      expect(json).to match(a_hash_including("timestamp" => "2023-11-21T18:30:00.000Z"))
    end
  end
end
