# frozen_string_literal: true

require "rails_helper"
require "openapi3_parser"

RSpec.describe "The Open API Specification document", show_exceptions: true do
  let!(:document) { Openapi3Parser.load_file(Rails.public_path.join("api/docs/v1/swagger_doc.yaml")) }
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:application_type) { create(:application_type) }

  before do
    stub_planx_api_response_for("POLYGON ((-0.07716178894042969 51.50094238217541, -0.07645905017852783 51.50053497847238, -0.07615327835083008 51.50115276135022, -0.07716178894042969 51.50094238217541))").to_return(
      status: 200, body: "{}"
    )
  end

  def example_request_json_for(path, http_method, example_name)
    document.paths[path][http_method].request_body.content["application/json"].examples[example_name].value.to_h.to_json
  end

  def example_response_json_for(path, http_method, response_code, example_name)
    document.paths[path][http_method].responses[response_code.to_s].content["application/json"].examples[example_name].value.to_h.to_json
  end

  def example_response_hash_for(*)
    JSON.parse(example_response_json_for(*))
  end

  it "is a valid oas3 document" do
    expect(document.valid?).to be(true)
  end

  it "successfully creates the ldc_proposed application as per the oas3 definition" do
    stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
      .to_return(
        status: 200,
        body: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").read,
        headers: {"Content-Type" => "application/pdf"}
      )
    expect do
      post "/api/v1/planning_applications",
        params: example_request_json_for("/api/v1/planning_applications", "post", "ldc_proposed"),
        headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}
    end.to change(PlanningApplication, :count).by(1)
    expect(response.code).to eq("200")
    expect(PlanningApplication.last.application_type.name).to eq("lawfulness_certificate")
    expect(PlanningApplication.last.description).to eq("Add a chimney stack")
    expect(PlanningApplication.last.payment_reference).to eq("PAY1")
    expect(PlanningApplication.last.payment_amount).to eq(103.00)
    expect(PlanningApplication.last.applicant_first_name).to eq("Albert")
    expect(PlanningApplication.last.applicant_last_name).to eq("Manteras")
    expect(PlanningApplication.last.applicant_phone).to eq("23432325435")
    expect(PlanningApplication.last.applicant_email).to eq("applicant@example.com")
    expect(PlanningApplication.last.agent_first_name).to eq("Jennifer")
    expect(PlanningApplication.last.agent_last_name).to eq("Harper")
    expect(PlanningApplication.last.agent_phone).to eq("237878889")
    expect(PlanningApplication.last.agent_email).to eq("agent@example.com")
    expect(PlanningApplication.last.user_role).to eq("agent")
    expect(PlanningApplication.last.address_1).to eq("11 Abbey Gardens")
    expect(PlanningApplication.last.address_2).to eq("Southwark")
    expect(PlanningApplication.last.uprn).to eq("100081043511")
    expect(PlanningApplication.last.town).to eq("London")
    expect(PlanningApplication.last.postcode).to eq("SE16 3RQ")
    expect(PlanningApplication.last.work_status).to eq("proposed")
    expect(PlanningApplication.last.boundary_geojson).to eq('{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-0.07716178894042969,51.50094238217541],[-0.07645905017852783,51.50053497847238],[-0.07615327835083008,51.50115276135022],[-0.07716178894042969,51.50094238217541]]]}}')
    expect(PlanningApplication.last.proposal_details.first.question).to eq("What do you want to do?")
    expect(PlanningApplication.last.documents.first.file).to be_present
    expect(PlanningApplication.last.documents.first.applicant_description).to eq("This is the side plan")
    expect(PlanningApplication.last.result_flag).to eq("Planning permission / Permission needed")
    expect(PlanningApplication.last.result_heading).to eq("It looks like these changes will need planning permission")
    expect(PlanningApplication.last.result_description).to eq("Based on the information you have provided, we do not think this is eligible for a Lawful Development Certificate")
    expect(PlanningApplication.last.result_override).to eq("This was my reason for rejecting the result")
  end

  it "successfully returns the listing of applications as specified" do
    travel_to(DateTime.new(2020, 5, 14))
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications", "get", 200,
      "ldc_proposed")["data"].first

    planning_application = PlanningApplication.create! planning_application_hash.except("reference", "reference_in_full",
      "received_date", "documents", "site", "constraints",
      "application_type").merge(
        local_authority:
        default_local_authority,
        application_type_id: ApplicationType.first.id
      )

    planning_application.update!(planning_application_hash["site"])
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url", "blob_url")) do |document|
      document.file.attach(io: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").open,
        filename: "roofplan")
      document.publishable = true
    end

    get "/api/v1/planning_applications"

    expected_response = example_response_hash_for("/api/v1/planning_applications", "get", 200, "ldc_proposed")
    expected_response["data"].first["documents"].first["url"] =
      api_v1_planning_application_document_url(planning_application, planning_application_document)

    expected_response["data"].first["documents"].first["blob_url"] =
      url_for(planning_application_document.file.representation(resize_to_limit: [1000, 1000])).to_s[/(?<=com).+/]

    expect(JSON.parse(response.body)).to eq(expected_response)
    travel_back
  end

  it "successfully returns an application as specified" do
    travel_to(DateTime.new(2020, 5, 14))
    planning_application_hash = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "ldc_proposed")
    planning_application = PlanningApplication.create! planning_application_hash.except("reference", "reference_in_full", "status",
      "received_date", "documents", "site", "constraints",
      "application_type").merge(
        local_authority: default_local_authority,
        application_type_id: ApplicationType.first.id,
        status: "in_assessment",
        validated_at: Time.zone.now
      )
    planning_application.update!(planning_application_hash["site"])
    planning_application_document = planning_application.documents.create!(planning_application_hash.fetch("documents").first.except("url", "blob_url")) do |document|
      document.file.attach(io: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").open,
        filename: "roofplan")
      document.publishable = true
    end

    get "/api/v1/planning_applications/#{planning_application_hash["id"]}"

    expected_response = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "ldc_proposed")
    expected_response["status"] = "in_assessment"
    expected_response["documents"].first["url"] =
      api_v1_planning_application_document_url(planning_application, planning_application_document)

    expected_response["documents"].first["blob_url"] =
      url_for(planning_application_document.file.representation(resize_to_limit: [1000, 1000])).to_s[/(?<=com).+/]

    expect(JSON.parse(response.body)).to eq(expected_response)
    travel_back
  end
end
