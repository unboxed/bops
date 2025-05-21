# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Parsers::AddressParser do
  describe "#parse" do

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
          uprn: "100023673934",
          address_1: "2, Brixton Hill",
          address_2: "Lambeth Town Hall",
          town: "London",
          postcode: "SW2 1RW",
          latitude: 175202,
          longitude: 530919
        )
      end
    end

    context "with missing longitude and latitude" do
      let(:params) do
        {
          "bs7666UniquePropertyReferenceNumber" => "123456789",
          "bs7666Number" => "10",
          "bs7666StreetDescription" => "Biscuit Lane",
          "bs7666Description" => "Westminster",
          "bs7666Town" => "London",
          "bs7666PostCode" => "SW2 AAA"
        }
      end

      it "returns a hash without lonlat" do
        expect(parse_address).to eq(
          uprn: "123456789",
          address_1: "10, Biscuit Lane",
          address_2: "Westminster",
          town: "London",
          postcode: "SW2 AAA",
          longitude: nil,
          latitude: nil
        )
      end
    end
  end
end
