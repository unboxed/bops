# frozen_string_literal: true

require "rails_helper"
require "openapi3_parser"

RSpec.describe "The Open API Specification document" do
  let!(:document) { Openapi3Parser.load_file(Rails.public_path.join("api/docs/v1/swagger_doc.yaml")) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :ldc_proposed) }
  let(:result) { PlanningApplication.last }

  before do
    stub_planx_api_response_for("POLYGON ((-0.07716178894042969 51.50094238217541, -0.07645905017852783 51.50053497847238, -0.07615327835083008 51.50115276135022, -0.07716178894042969 51.50094238217541))").to_return(
      status: 200, body: "{}"
    )
  end

  def example_request_json_for(path, http_method, example_name)
    value = document.paths[path][http_method].request_body.content["application/json"].examples[example_name].value.merge(
      planx_debug_data: {passport: {data: {
        "application.fee.calculated": 206,
        "application.fee.payable": 103,
        "application.fee.reduction.parishCouncil": ["true"]
      }}}
    )

    value.to_json
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

  it "successfully returns an application as specified" do
    travel_to("2020-05-14") do
      planning_application_hash = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "ldc_proposed")
      planning_application = PlanningApplication.create! planning_application_hash.except("reference", "reference_in_full", "status",
        "received_date", "documents", "site", "constraints", "work_status",
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

      expected_response = example_response_hash_for("/api/v1/planning_applications/{id}", "get", 200, "ldc_proposed")
      expected_response["status"] = "in_assessment"
      expected_response["documents"].first["url"] = "http://planx.example.com/api/v1/planning_applications/#{planning_application.reference}/documents/#{planning_application_document.id}"
      expected_response["documents"].first["blob_url"] = "http://uploads.example.com/#{planning_application_document.representation.key}"

      get("/api/v1/planning_applications/#{planning_application_hash["id"]}", headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"})
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end
end
