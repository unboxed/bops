# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Open API Specification document", type: :request, show_exceptions: true do
  let(:document) { Openapi3Parser.load_file(Rails.root.join("public/api-docs/v1/swagger_doc.yaml")) }
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

  it "successfullies create the Minimum application as per the oas3 definition" do
    expect {
      post "/api/v1/planning_applications",
           params: example_request_json_for("/api/v1/planning_applications", "post", "Minimum"),
           headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    }.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq("200")
    expect(PlanningApplication.last.application_type).to eq("lawfulness_certificate")
  end

  it "successfullies create the Full application as per the oas3 definition" do
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
    expect(PlanningApplication.last.ward).to eq("Dulwich Wood")
    expect(PlanningApplication.last.applicant_first_name).to eq("Albert")
    expect(PlanningApplication.last.applicant_last_name).to eq("Manteras")
    expect(PlanningApplication.last.applicant_phone).to eq("23432325435")
    expect(PlanningApplication.last.applicant_email).to eq("applicant@example.com")
    expect(PlanningApplication.last.agent_first_name).to eq("Jennifer")
    expect(PlanningApplication.last.agent_last_name).to eq("Harper")
    expect(PlanningApplication.last.agent_phone).to eq("237878889")
    expect(PlanningApplication.last.agent_email).to eq("agent@example.com")
    expect(PlanningApplication.last.work_status).to eq("proposed")
    expect(JSON.parse(PlanningApplication.last.proposal_details).first["question"]).to eq("What do you want to do?")
    expect(JSON.parse(PlanningApplication.last.constraints)["conservation_area"]).to eq(true)
    expect(PlanningApplication.last.documents.first.file).to be_present
  end

  it "successfullies return the listing of applications as specified" do
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications", "get", 200, "Full")["data"].first
    site = Site.create! planning_application_hash.fetch("site")
    planning_application = PlanningApplication.create! planning_application_hash.except("application_number", "received_date", "documents").merge(site: site, local_authority: @default_local_authority)
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url")) do |document|
      document.file.attach(io: File.open(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")), filename: "roofplan")
    end

    get "/api/v1/planning_applications"

    expected_reponse = example_response_hash_for("/api/v1/planning_applications", "get", 200, "Full")
    expected_reponse["data"].first["documents"].first["url"] = api_v1_planning_application_document_url(planning_application, planning_application_document)
    expect(JSON.parse(response.body)).to eq(expected_reponse)
  end

  it "successfullies return an application as specified" do
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "Full")
    site = Site.create! planning_application_hash.fetch("site")
    planning_application = PlanningApplication.create! planning_application_hash.except("application_number", "received_date", "documents").merge(site: site, local_authority: @default_local_authority)
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url")) do |document|
      document.file.attach(io: File.open(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf")), filename: "roofplan")
    end

    get "/api/v1/planning_applications/#{planning_application_hash['id']}"

    expected_reponse = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "Full")
    expected_reponse["documents"].first["url"] = api_v1_planning_application_document_url(planning_application, planning_application_document)
    expect(JSON.parse(response.body)).to eq(expected_reponse)
  end
end
