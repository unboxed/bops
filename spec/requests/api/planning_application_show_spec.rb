# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list planning applications" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer) }
  let!(:planning_application) do
    create(:planning_application, :in_assessment, :with_constraints, local_authority: default_local_authority, decision: "granted", api_user:)
  end
  let!(:lambeth) { create(:local_authority, :lambeth) }
  let!(:planning_application_lambeth) { create(:planning_application, :not_started, local_authority: lambeth) }
  let!(:planning_application_not_validated) { create(:planning_application, :not_started, local_authority: default_local_authority) }
  let(:token) { "Bearer #{api_user.token}" }
  let(:headers) do
    {"CONTENT-TYPE": "application/json",
     Authorization: "Bearer #{api_user.token}"}
  end

  describe "format" do
    let(:access_control_allow_origin) { response.headers["Access-Control-Allow-Origin"] }
    let(:access_control_allow_methods) { response.headers["Access-Control-Allow-Methods"] }
    let(:access_control_allow_headers) { response.headers["Access-Control-Allow-Headers"] }

    it "responds to JSON" do
      get("/api/v1/planning_applications/#{planning_application.reference}", headers: headers)
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get("/api/v1/planning_applications/#{planning_application.reference}", headers: headers)

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq("*")
      expect(access_control_allow_methods).to eq("*")
      expect(access_control_allow_headers).to eq("Origin, X-Requested-With, Content-Type, Accept")
    end
  end

  describe "data" do
    let(:planning_application_json) { json }

    it "returns a 404 if no planning application" do
      get("/api/v1/planning_applications/xxx", headers:)
      expect(response.code).to eq("404")
      expect(planning_application_json).to eq({"message" => "Unable to find record"})
    end

    it "returns 404 if planning application is from another authority" do
      get("/api/v1/planning_applications/#{planning_application_lambeth.id}", headers:)
      expect(response.code).to eq("404")
      expect(planning_application_json).to eq({"message" => "Unable to find record"})
    end

    context "with a new planning application" do
      it "returns the accurate data" do
        get("/api/v1/planning_applications/#{planning_application.reference}", headers: headers)
        expect(planning_application_json["status"]).to eq("in_assessment")
        expect(planning_application_json["id"]).to eq(planning_application.id)
        expect(planning_application_json["reference"]).to eq(planning_application.reference)
        expect(planning_application_json["reference_in_full"]).to eq(planning_application.reference_in_full)
        expect(planning_application_json["application_type"]).to eq("lawfulness_certificate")
        expect(planning_application_json["description"]).to eq(planning_application.description)
        expect(planning_application_json["received_date"]).to eq(json_time_format(planning_application.received_at))
        expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
        expect(planning_application_json["determination_date"]).to eq(planning_application.determination_date.to_fs(:db))
        expect(planning_application_json["decision"]).to be_nil
        expect(planning_application_json["target_date"]).to eq(planning_application.target_date.to_fs(:db))
        expect(planning_application_json["started_at"]).to eq(json_time_format(planning_application.started_at))
        expect(planning_application_json["created_at"]).to eq(json_time_format(planning_application.created_at))
        expect(planning_application_json["invalidated_at"]).to eq(json_time_format(planning_application.invalidated_at))
        expect(planning_application_json["withdrawn_at"]).to eq(json_time_format(planning_application.withdrawn_at))
        expect(planning_application_json["work_status"]).to eq(planning_application.work_status)
        expect(planning_application_json["payment_reference"]).to eq(planning_application.payment_reference)
        expect(planning_application_json["payment_amount"].to_d).to eq(planning_application.payment_amount)
        expect(planning_application_json["awaiting_determination_at"]).to eq(json_time_format(planning_application.awaiting_determination_at))
        expect(planning_application_json["in_assessment_at"]).to eq(json_time_format(planning_application.in_assessment_at))
        expect(planning_application_json["to_be_reviewed_at"]).to eq(json_time_format(planning_application.to_be_reviewed_at))
        expect(planning_application_json["agent_first_name"]).to eq(planning_application.agent_first_name)
        expect(planning_application_json["agent_last_name"]).to eq(planning_application.agent_last_name)
        expect(planning_application_json["agent_email"]).to eq(planning_application.agent_email)
        expect(planning_application_json["applicant_first_name"]).to eq(planning_application.applicant_first_name)
        expect(planning_application_json["applicant_last_name"]).to eq(planning_application.applicant_last_name)
        expect(planning_application_json["site"]["address_1"]).to eq(planning_application.address_1)
        expect(planning_application_json["site"]["address_2"]).to eq(planning_application.address_2)
        expect(planning_application_json["site"]["town"]).to eq(planning_application.town)
        expect(planning_application_json["site"]["county"]).to eq(planning_application.county)
        expect(planning_application_json["site"]["postcode"]).to eq(planning_application.postcode)
        expect(planning_application_json["site"]["uprn"]).to eq(planning_application.uprn)
        expect(planning_application_json["constraints"]).to eq(["Conservation area", "Listed building outline"])
        expect(planning_application_json["documents"]).to eq([])
      end

      context "when granted planning application" do
        let!(:planning_application) do
          create(:planning_application, :determined, :planning_permission, :with_constraints, local_authority: default_local_authority, decision: "granted", api_user:)
        end
        let!(:document_with_number) { create(:document, :public, planning_application:) }
        let!(:document_without_number) { create(:document, planning_application:) }
        let!(:document_archived) { create(:document, :public, :archived, planning_application:) }
        let!(:consultation) { planning_application.consultation }
        let!(:neighbour) { create(:neighbour, consultation:) }
        let!(:neighbour_response) { create(:neighbour_response, neighbour:, redacted_response: "It's fine", received_at: 1.day.ago, summary_tag: "supportive") }

        it "returns the accurate data" do
          get("/api/v1/planning_applications/#{planning_application.reference}", headers: headers)
          expect(planning_application_json["status"]).to eq("determined")
          expect(planning_application_json["id"]).to eq(planning_application.id)
          expect(planning_application_json["reference"]).to eq(planning_application.reference)
          expect(planning_application_json["reference_in_full"]).to eq(planning_application.reference_in_full)
          expect(planning_application_json["application_type"]).to eq("planning_permission")
          expect(planning_application_json["description"]).to eq(planning_application.description)
          expect(planning_application_json["received_date"]).to eq(json_time_format(planning_application.received_at))
          expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
          expect(planning_application_json["determination_date"]).to eq(json_time_format(planning_application.determination_date))
          expect(planning_application_json["decision"]).to eq("granted")
          expect(planning_application_json["target_date"]).to eq(planning_application.target_date.to_fs(:db))
          expect(planning_application_json["started_at"]).to eq(json_time_format(planning_application.started_at))
          expect(planning_application_json["created_at"]).to eq(json_time_format(planning_application.created_at))
          expect(planning_application_json["invalidated_at"]).to eq(json_time_format(planning_application.invalidated_at))
          expect(planning_application_json["withdrawn_at"]).to eq(json_time_format(planning_application.withdrawn_at))
          expect(planning_application_json["work_status"]).to eq(planning_application.work_status)
          expect(planning_application_json["payment_reference"]).to eq(planning_application.payment_reference)
          expect(planning_application_json["payment_amount"].to_d).to eq(planning_application.payment_amount)
          expect(planning_application_json["awaiting_determination_at"]).to eq(json_time_format(planning_application.awaiting_determination_at))
          expect(planning_application_json["in_assessment_at"]).to eq(json_time_format(planning_application.in_assessment_at))
          expect(planning_application_json["to_be_reviewed_at"]).to eq(json_time_format(planning_application.to_be_reviewed_at))
          expect(planning_application_json["agent_first_name"]).to eq(planning_application.agent_first_name)
          expect(planning_application_json["agent_last_name"]).to eq(planning_application.agent_last_name)
          expect(planning_application_json["agent_email"]).to eq(planning_application.agent_email)
          expect(planning_application_json["applicant_first_name"]).to eq(planning_application.applicant_first_name)
          expect(planning_application_json["applicant_last_name"]).to eq(planning_application.applicant_last_name)
          expect(planning_application_json["user_role"]).to eq(planning_application.user_role)
          expect(planning_application_json["site"]["address_1"]).to eq(planning_application.address_1)
          expect(planning_application_json["site"]["address_2"]).to eq(planning_application.address_2)
          expect(planning_application_json["site"]["town"]).to eq(planning_application.town)
          expect(planning_application_json["site"]["county"]).to eq(planning_application.county)
          expect(planning_application_json["site"]["postcode"]).to eq(planning_application.postcode)
          expect(planning_application_json["site"]["uprn"]).to eq(planning_application.uprn)
          expect(planning_application_json["site"]["latitude"]).to eq(planning_application.latitude)
          expect(planning_application_json["site"]["longitude"]).to eq(planning_application.longitude)
          expect(planning_application_json["constraints"]).to eq(["Conservation area", "Listed building outline"])
          expect(planning_application_json["documents"].size).to eq(1)

          planning_application_json["documents"].first.tap do |document_json|
            expect(document_json["url"]).to eq("http://planx.example.com/api/v1/planning_applications/#{planning_application.reference}/documents/#{document_with_number.id}")
            expect(document_json["blob_url"]).to eq("http://uploads.example.com/#{document_with_number.representation.key}")
            expect(document_json["created_at"]).to eq(json_time_format(document_with_number.created_at))
            expect(document_json["archived_at"]).to eq(json_time_format(document_with_number.archived_at))
            expect(document_json["archive_reason"]).to eq(document_with_number.archive_reason)
            expect(document_json["tags"]).to eq(document_with_number.tags)
            expect(document_json["numbers"]).to eq(document_with_number.numbers)
          end

          planning_application_json["published_comments"].first.tap do |comment_json|
            expect(comment_json["comment"]).to eq(neighbour_response.redacted_response)
            expect(comment_json["received_at"]).to eq(json_time_format(neighbour_response.received_at))
            expect(comment_json["summary_tag"]).to eq(neighbour_response.summary_tag)
          end
        end
      end
    end
  end
end
