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
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:applicant]
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
  end
end
