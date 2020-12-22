# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "The Open API Specification document", type: :request, show_exceptions: true do
  let(:document) { Openapi3Parser.load_file(Rails.root.join('public/api-docs/v1/swagger_doc.yaml')) }
  let(:api_user) { create :api_user }

  def example_at_in_json(path, http_method, example_name)
    document.paths[path][http_method].request_body.content['application/json'].examples[example_name].value.to_h.to_json
  end

  it "should be a valid oas3 document" do
    expect(document.valid?).to eq(true)
  end

  it "should successfully create the Minimum application as per the oas3 definition" do
    expect {
      post "/api/v1/planning_applications",
        params: example_at_in_json('/api/v1/planning_applications', 'post', 'Minimum'),
        headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    }.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq('200')
    expect(PlanningApplication.last.application_type).to eq('full')
  end
end
