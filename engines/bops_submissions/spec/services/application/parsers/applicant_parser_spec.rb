# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::ApplicantParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_applicant) do
      described_class.new(params, source: "Planning Portal", local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        json_fixture_submissions("files/applications/PT-10087984.json")["applicationData"]["applicant"]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_applicant).to eq(
          applicant_first_name: "Bob",
          applicant_last_name: "Smith",
          applicant_email: "test@lambeth.gov.uk",
          applicant_phone: "070000000"
        )
      end
    end

    context "with missing input params" do
      let(:params) { {} }

      it "returns an empty hash" do
        expect(parse_applicant).to eq({})
      end
    end
  end
end
