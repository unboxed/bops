# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "API request to list planning applications", type: :request, show_exceptions: true do
  let(:api_user) { create :api_user }
  let(:reviewer) { create :user, :reviewer }
  let!(:planning_application) { create(:planning_application, :not_started) }

  describe "format" do
    let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
    let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
    let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

    it "responds to JSON" do
      get "/api/v1/planning_applications/#{planning_application.id}"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/api/v1/planning_applications/#{planning_application.id}"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('*')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
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

    context "for a new planning application" do
      it "returns the accurate data" do
        get "/api/v1/planning_applications/#{planning_application.id}"
        expect(planning_application_json["status"]).to eq('not_started')
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
        expect(planning_application_json["ward"]).to eq(planning_application.ward)
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
        expect(planning_application_json["site"]["address_1"]).to eq(planning_application.site.address_1)
        expect(planning_application_json["site"]["address_2"]).to eq(planning_application.site.address_2)
        expect(planning_application_json["site"]["town"]).to eq(planning_application.site.town)
        expect(planning_application_json["site"]["county"]).to eq(planning_application.site.county)
        expect(planning_application_json["site"]["postcode"]).to eq(planning_application.site.postcode)
        expect(planning_application_json["site"]["uprn"]).to eq(planning_application.site.uprn)
        expect(planning_application_json["questions"]).to eq(JSON.parse(planning_application.questions))
        expect(planning_application_json["constraints"]).to eq(JSON.parse(planning_application.constraints))
      end

      context "for a granted planning application" do
        let!(:planning_application) { create(:planning_application, :determined) }
        let!(:decision) { create(:decision, :granted, user: reviewer, planning_application: planning_application) }

        it "returns the accurate data" do
          get "/api/v1/planning_applications/#{planning_application.id}"
          expect(planning_application_json["status"]).to eq('determined')
          expect(planning_application_json["id"]).to eq(planning_application.id)
          expect(planning_application_json["application_number"]).to eq(planning_application.reference)
          expect(planning_application_json["application_type"]).to eq("lawfulness_certificate")
          expect(planning_application_json["description"]).to eq(planning_application.description)
          expect(planning_application_json["received_date"]).to eq(json_time_format(planning_application.created_at))
          expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
          expect(planning_application_json["decision"]).to eq('granted')
          expect(planning_application_json["target_date"]).to eq(planning_application.target_date.to_s)
          expect(planning_application_json["started_at"]).to eq(json_time_format(planning_application.started_at))
          expect(planning_application_json["determined_at"]).to eq(json_time_format(planning_application.determined_at))
          expect(planning_application_json["created_at"]).to eq(json_time_format(planning_application.created_at))
          expect(planning_application_json["invalidated_at"]).to eq(json_time_format(planning_application.invalidated_at))
          expect(planning_application_json["withdrawn_at"]).to eq(json_time_format(planning_application.withdrawn_at))
          expect(planning_application_json["ward"]).to eq(planning_application.ward)
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
          expect(planning_application_json["site"]["address_1"]).to eq(planning_application.site.address_1)
          expect(planning_application_json["site"]["address_2"]).to eq(planning_application.site.address_2)
          expect(planning_application_json["site"]["town"]).to eq(planning_application.site.town)
          expect(planning_application_json["site"]["county"]).to eq(planning_application.site.county)
          expect(planning_application_json["site"]["postcode"]).to eq(planning_application.site.postcode)
          expect(planning_application_json["site"]["uprn"]).to eq(planning_application.site.uprn)
          expect(planning_application_json["questions"]).to eq(JSON.parse(planning_application.questions))
          expect(planning_application_json["constraints"]).to eq(JSON.parse(planning_application.constraints))
        end
      end
    end
  end
end
