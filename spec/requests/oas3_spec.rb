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

  it "should successfully create the Full application as per the oas3 definition" do
    stub_request(:get, "https://bops-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf").
        to_return(status: 200, body: File.read(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")))
    expect {
      post "/api/v1/planning_applications",
        params: example_at_in_json('/api/v1/planning_applications', 'post', 'Full'),
        headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    }.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq('200')
    expect(PlanningApplication.last.application_type).to eq('full')
    expect(PlanningApplication.last.description).to eq('Add a chimney stack')
    expect(PlanningApplication.last.payment_reference).to eq('PAY1')
    expect(PlanningApplication.last.ward).to eq('Dulwich Wood')
    expect(PlanningApplication.last.applicant_first_name).to eq('Albert')
    expect(PlanningApplication.last.applicant_last_name).to eq('Manteras')
    expect(PlanningApplication.last.applicant_phone).to eq('23432325435')
    expect(PlanningApplication.last.applicant_email).to eq('applicant@example.com')
    expect(PlanningApplication.last.agent_first_name).to eq('Jennifer')
    expect(PlanningApplication.last.agent_last_name).to eq('Harper')
    expect(PlanningApplication.last.agent_phone).to eq('237878889')
    expect(PlanningApplication.last.agent_email).to eq('agent@example.com')
    expect(JSON.parse(PlanningApplication.last.questions)['flow'].first['text']).to eq('The property is')
    expect(JSON.parse(PlanningApplication.last.constraints)['conservation_area']).to eq(true)
    expect(PlanningApplication.last.drawings.first.plan).to be_present
  end
end
