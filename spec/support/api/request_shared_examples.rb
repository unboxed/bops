# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ApiRequest::Forbidden" do
  it "returns a 401 if API key is invalid" do
    get "#{path}?change_access_id=#{planning_application.change_access_id}",
        headers: { "CONTENT-TYPE": "application/json", Authorization: "invalidtoken" }

    expect(response).to have_http_status(:unauthorized)
    expect(json).to eq({ "error" => "HTTP Token: Access denied." })
  end

  it "returns a 401 if change_access_id is invalid" do
    get "#{path}?change_access_id=invalidchangeaccessid",
        headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:unauthorized)
    expect(json).to eq({ "message" => "Change access id is invalid" })
  end
end

RSpec.shared_examples "ApiRequest::NotFound" do |entity|
  it "returns a 404" do
    get "#{path}?change_access_id=#{planning_application.change_access_id}",
        headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:not_found)
    expect(json).to eq({ "message" => "Unable to find #{entity.humanize.downcase} with id: #{send(entity).id + 1}" })
  end
end
