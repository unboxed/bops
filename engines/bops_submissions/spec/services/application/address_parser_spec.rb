# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Parsers::AddressParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_address) do
      described_class.new(params).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_portal_planning_permission.json").read)
        )["applicationData"]["siteLocation"]
      }

      it "returns a correctly formatted address hash" do
        expect(parse_address).to eq(
          uprn: 100023673934,
          address_1: "2, Brixton Hill",
          address_2: "Lambeth Town Hall",
          town: "London",
          postcode: "SW2 1RW",
          latitude: 175202,
          longitude: 530919
        )
      end
    end
  end
end
