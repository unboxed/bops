# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "GET /healthcheck" do
  it "returns 200 OK" do
    get "/healthcheck"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("OK")
  end
end
