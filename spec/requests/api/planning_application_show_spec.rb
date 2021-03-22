# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list planning applications", type: :request, show_exceptions: true do
  let(:reviewer) { create :user, :reviewer }
  let!(:planning_application) { create(:planning_application, :not_started, local_authority: @default_local_authority, decision: "granted") }
  let(:lambeth) { create :local_authority, subdomain: "lambeth" }
  let!(:planning_application_lambeth) { create(:planning_application, :not_started, local_authority: lambeth) }

  describe "format" do
    let(:access_control_allow_origin) { response.headers["Access-Control-Allow-Origin"] }
    let(:access_control_allow_methods) { response.headers["Access-Control-Allow-Methods"] }
    let(:access_control_allow_headers) { response.headers["Access-Control-Allow-Headers"] }

    it "responds to JSON" do
      get "/api/v1/planning_applications/#{planning_application.id}"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/api/v1/planning_applications/#{planning_application.id}"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq("*")
      expect(access_control_allow_methods).to eq("*")
      expect(access_control_allow_headers).to eq("Origin, X-Requested-With, Content-Type, Accept")
    end
  end

  describe "data" do
    let(:planning_application_json) { json }

    def json_time_format(time)
      time.utc.iso8601(3) if time.present?
    end

    it "returns a 404 if no planning application" do
      get "/api/v1/planning_applications/xxx"
      expect(response.code).to eq("404")
      expect(planning_application_json).to eq({ "message" => "Unable to find record" })
    end

    it "returns 404 if planning application is from another authority" do
      get "/api/v1/planning_applications/#{planning_application_lambeth.id}"
      expect(response.code).to eq("404")
      expect(planning_application_json).to eq({ "message" => "Unable to find record" })
    end

    context "for a new planning application" do
      it "returns the accurate data" do
        get "/api/v1/planning_applications/#{planning_application.id}"
        expect(planning_application_json["status"]).to eq("not_started")
        expect(planning_application_json["id"]).to eq(planning_application.id)
        expect(planning_application_json["application_number"]).to eq(planning_application.reference)
        expect(planning_application_json["application_type"]).to eq("lawfulness_certificate")
        expect(planning_application_json["description"]).to eq(planning_application.description)
        expect(planning_application_json["received_date"]).to eq(json_time_format(planning_application.created_at))
        expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
        expect(planning_application_json["decision"]).to eq(nil)
        expect(planning_application_json["target_date"]).to eq(planning_application.target_date.to_s)
        expect(planning_application_json["started_at"]).to eq(json_time_format(planning_application.started_at))
        expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
        expect(planning_application_json["created_at"]).to eq(json_time_format(planning_application.created_at))
        expect(planning_application_json["invalidated_at"]).to eq(json_time_format(planning_application.invalidated_at))
        expect(planning_application_json["withdrawn_at"]).to eq(json_time_format(planning_application.withdrawn_at))
        expect(planning_application_json["work_status"]).to eq(planning_application.work_status)
        expect(planning_application_json["payment_reference"]).to eq(planning_application.payment_reference)
        expect(planning_application_json["awaiting_determination_at"]).to eq(json_time_format(planning_application.awaiting_determination_at))
        expect(planning_application_json["in_assessment_at"]).to eq(json_time_format(planning_application.in_assessment_at))
        expect(planning_application_json["awaiting_correction_at"]).to eq(json_time_format(planning_application.awaiting_correction_at))
        expect(planning_application_json["agent_first_name"]).to eq(planning_application.agent_first_name)
        expect(planning_application_json["agent_last_name"]).to eq(planning_application.agent_last_name)
        expect(planning_application_json["agent_email"]).to eq(planning_application.agent_email)
        expect(planning_application_json["applicant_first_name"]).to eq(planning_application.applicant_first_name)
        expect(planning_application_json["applicant_last_name"]).to eq(planning_application.applicant_last_name)
        expect(planning_application_json["applicant_email"]).to eq(planning_application.applicant_email)
        expect(planning_application_json["applicant_phone"]).to eq(planning_application.applicant_phone)
        expect(planning_application_json["site"]["address_1"]).to eq(planning_application.address_1)
        expect(planning_application_json["site"]["address_2"]).to eq(planning_application.address_2)
        expect(planning_application_json["site"]["town"]).to eq(planning_application.town)
        expect(planning_application_json["site"]["county"]).to eq(planning_application.county)
        expect(planning_application_json["site"]["postcode"]).to eq(planning_application.postcode)
        expect(planning_application_json["site"]["uprn"]).to eq(planning_application.uprn)
        expect(planning_application_json["proposal_details"]).to eq(JSON.parse(planning_application.proposal_details))
        expect(planning_application_json["constraints"]).to eq(JSON.parse(planning_application.constraints))
        expect(planning_application_json["documents"]).to eq([])
      end

      context "for a granted planning application" do
        let!(:planning_application) { create(:planning_application, :determined, local_authority: @default_local_authority, decision: "granted") }
        let!(:document_with_number) { create(:document, :public, planning_application: planning_application) }
        let!(:document_without_number) { create(:document, planning_application: planning_application) }
        let!(:document_archived) { create(:document, :public, :archived, planning_application: planning_application) }

        it "returns the accurate data" do
          get "/api/v1/planning_applications/#{planning_application.id}"
          expect(planning_application_json["status"]).to eq("determined")
          expect(planning_application_json["id"]).to eq(planning_application.id)
          expect(planning_application_json["application_number"]).to eq(planning_application.reference)
          expect(planning_application_json["application_type"]).to eq("lawfulness_certificate")
          expect(planning_application_json["description"]).to eq(planning_application.description)
          expect(planning_application_json["received_date"]).to eq(json_time_format(planning_application.created_at))
          expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
          expect(planning_application_json["decision"]).to eq("granted")
          expect(planning_application_json["target_date"]).to eq(planning_application.target_date.to_s)
          expect(planning_application_json["started_at"]).to eq(json_time_format(planning_application.started_at))
          expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
          expect(planning_application_json["created_at"]).to eq(json_time_format(planning_application.created_at))
          expect(planning_application_json["invalidated_at"]).to eq(json_time_format(planning_application.invalidated_at))
          expect(planning_application_json["withdrawn_at"]).to eq(json_time_format(planning_application.withdrawn_at))
          expect(planning_application_json["work_status"]).to eq(planning_application.work_status)
          expect(planning_application_json["payment_reference"]).to eq(planning_application.payment_reference)
          expect(planning_application_json["awaiting_determination_at"]).to eq(json_time_format(planning_application.awaiting_determination_at))
          expect(planning_application_json["in_assessment_at"]).to eq(json_time_format(planning_application.in_assessment_at))
          expect(planning_application_json["awaiting_correction_at"]).to eq(json_time_format(planning_application.awaiting_correction_at))
          expect(planning_application_json["agent_first_name"]).to eq(planning_application.agent_first_name)
          expect(planning_application_json["agent_last_name"]).to eq(planning_application.agent_last_name)
          expect(planning_application_json["agent_email"]).to eq(planning_application.agent_email)
          expect(planning_application_json["applicant_first_name"]).to eq(planning_application.applicant_first_name)
          expect(planning_application_json["applicant_last_name"]).to eq(planning_application.applicant_last_name)
          expect(planning_application_json["applicant_email"]).to eq(planning_application.applicant_email)
          expect(planning_application_json["applicant_phone"]).to eq(planning_application.applicant_phone)
          expect(planning_application_json["site"]["address_1"]).to eq(planning_application.address_1)
          expect(planning_application_json["site"]["address_2"]).to eq(planning_application.address_2)
          expect(planning_application_json["site"]["town"]).to eq(planning_application.town)
          expect(planning_application_json["site"]["county"]).to eq(planning_application.county)
          expect(planning_application_json["site"]["postcode"]).to eq(planning_application.postcode)
          expect(planning_application_json["site"]["uprn"]).to eq(planning_application.uprn)
          expect(planning_application_json["proposal_details"]).to eq(JSON.parse(planning_application.proposal_details))
          expect(planning_application_json["constraints"]).to eq(JSON.parse(planning_application.constraints))
          expect(planning_application_json["documents"].size).to eq(1)
          expect(planning_application_json["documents"].first["url"]).to eq(api_v1_planning_application_document_url(planning_application, document_with_number))
          expect(planning_application_json["documents"].first["created_at"]).to eq(json_time_format(document_with_number.created_at))
          expect(planning_application_json["documents"].first["archived_at"]).to eq(json_time_format(document_with_number.archived_at))
          expect(planning_application_json["documents"].first["archive_reason"]).to eq(document_with_number.archive_reason)
          expect(planning_application_json["documents"].first["tags"]).to eq(document_with_number.tags)
          expect(planning_application_json["documents"].first["numbers"]).to eq(document_with_number.numbers)
        end
      end
    end
  end
end
