# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::ApplicantParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_applicant) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        JSON.parse(file_fixture("v2/valid_planning_permission.json").read).with_indifferent_access[:data][:applicant]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_applicant).to eq(
          applicant_first_name: "David",
          applicant_last_name: "Bowie",
          applicant_email: "ziggy@example.com",
          applicant_phone: "Not provided by agent"
        )
      end
    end

    context "preapplication when applicant has a different contact address" do
      let(:params) {
        JSON.parse(file_fixture("v2/preapp_submission.json").read).with_indifferent_access[:data][:applicant]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_applicant).to eq(
          applicant_first_name: "David",
          applicant_last_name: "Bowie",
          applicant_email: "ziggy@example.com",
          applicant_phone: "0740 2222222",
          applicant_address_1: "Applicant Test Street",
          applicant_address_2: "Applicant Test Borough",
          applicant_town: "Applicant Test Town",
          applicant_county: "Applicant Test County",
          applicant_postcode: "N7 8AL",
          applicant_country: "United Kingdom"
        )
      end
    end
  end
end
