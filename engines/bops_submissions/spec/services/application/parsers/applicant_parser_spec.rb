# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Parsers::ApplicantParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_applicant) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_portal_planning_permission.json").read)
        )["applicationData"]["applicant"]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_applicant).to eq(
          applicant_first_name: "John",
          applicant_last_name: "Doe",
          applicant_email: "example_applicant@planningportal.com",
          applicant_phone: "070000000"
        )
      end
    end
  end
end
