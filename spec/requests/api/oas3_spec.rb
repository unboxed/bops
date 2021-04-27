# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Open API Specification document", type: :request, show_exceptions: true do
  let(:document) { Openapi3Parser.load_file(Rails.root.join("public/api-docs/v1/_build/swagger_doc.yaml")) }
  let(:api_user) { create :api_user }

  def example_request_json_for(path, http_method, example_name)
    document.paths[path][http_method].request_body.content["application/json"].examples[example_name].value.to_h.to_json
  end

  def example_response_json_for(path, http_method, response_code, example_name)
    document.paths[path][http_method].responses[response_code.to_s].content["application/json"].examples[example_name].value.to_h.to_json
  end

  def example_response_hash_for(*attrs)
    JSON.parse(example_response_json_for(*attrs))
  end

  it "is a valid oas3 document" do
    expect(document.valid?).to eq(true)
  end

  it "successfully creates the Minimum application as per the oas3 definition" do
    expect {
      post "/api/v1/planning_applications",
           params: example_request_json_for("/api/v1/planning_applications", "post", "Minimum"),
           headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    }.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq("200")
    expect(PlanningApplication.last.application_type).to eq("lawfulness_certificate")
  end

  it "successfully creates the Full application as per the oas3 definition" do
    stub_request(:get, "https://bops-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(status: 200, body: File.read(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")))
    expect {
      post "/api/v1/planning_applications",
           params: example_request_json_for("/api/v1/planning_applications", "post", "Full"),
           headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    }.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq("200")
    expect(PlanningApplication.last.application_type).to eq("lawfulness_certificate")
    expect(PlanningApplication.last.description).to eq("Add a chimney stack")
    expect(PlanningApplication.last.payment_reference).to eq("PAY1")
    expect(PlanningApplication.last.applicant_first_name).to eq("Albert")
    expect(PlanningApplication.last.applicant_last_name).to eq("Manteras")
    expect(PlanningApplication.last.applicant_phone).to eq("23432325435")
    expect(PlanningApplication.last.applicant_email).to eq("applicant@example.com")
    expect(PlanningApplication.last.agent_first_name).to eq("Jennifer")
    expect(PlanningApplication.last.agent_last_name).to eq("Harper")
    expect(PlanningApplication.last.agent_phone).to eq("237878889")
    expect(PlanningApplication.last.agent_email).to eq("agent@example.com")
    expect(PlanningApplication.last.address_1).to eq("11 Abbey Gardens")
    expect(PlanningApplication.last.address_2).to eq("Southwark")
    expect(PlanningApplication.last.uprn).to eq("100081043511")
    expect(PlanningApplication.last.town).to eq("London")
    expect(PlanningApplication.last.postcode).to eq("SE16 3RQ")
    expect(PlanningApplication.last.work_status).to eq("proposed")
    expect(PlanningApplication.last.boundary_geojson).to eq('{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-0.07716178894042969,51.50094238217541],[-0.07645905017852783,51.50053497847238],[-0.07615327835083008,51.50115276135022],[-0.07716178894042969,51.50094238217541]]]}}')
    expect(JSON.parse(PlanningApplication.last.proposal_details).first["question"]).to eq("What do you want to do?")
    expect(PlanningApplication.last.constraints).to eq(%w[conservation_area])
    expect(PlanningApplication.last.documents.first.file).to be_present
  end

  it "successfully returns the listing of applications as specified" do
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications", "get", 200, "Full")["data"].first
    planning_application = PlanningApplication.create! planning_application_hash.except("application_number", "received_date", "documents", "site").merge(local_authority: @default_local_authority)
    planning_application.update!(planning_application_hash["site"])
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url")) do |document|
      document.file.attach(io: File.open(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")), filename: "roofplan")
      document.publishable = true
    end

    get "/api/v1/planning_applications"

    expected_response = example_response_hash_for("/api/v1/planning_applications", "get", 200, "Full")
    expected_response["data"].first["documents"].first["url"] = api_v1_planning_application_document_url(planning_application, planning_application_document)
    expect(JSON.parse(response.body)).to eq(expected_response)
  end

  it "successfully returns an application as specified" do
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "Full")
    planning_application = PlanningApplication.create! planning_application_hash.except("application_number", "received_date", "documents", "site").merge(local_authority: @default_local_authority)
    planning_application.update!(planning_application_hash["site"])
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url")) do |document|
      document.file.attach(io: File.open(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")), filename: "roofplan")
      document.publishable = true
    end

    get "/api/v1/planning_applications/#{planning_application_hash['id']}"

    expected_response = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "Full")
    expected_response["documents"].first["url"] = api_v1_planning_application_document_url(planning_application, planning_application_document)
    expect(JSON.parse(response.body)).to eq(expected_response)
  end
end
