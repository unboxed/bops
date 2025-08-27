# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::AddressParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_address) do
      described_class.new(params, source: "Planning Portal", local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        json_fixture_submissions("files/applications/PT-10087984.json")["applicationData"]["siteLocation"]
      }

      it "returns a correctly formatted address hash" do
        expect(parse_address).to eq(
          uprn: "100023673934",
          address_1: "2, Brixton Hill",
          address_2: "Lambeth Town Hall",
          town: "London",
          postcode: "SW2 1RW",
          map_east: 530919,
          map_north: 175202
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

      it "returns a hash without easting/ northing" do
        expect(parse_address).to eq(
          uprn: "123456789",
          address_1: "10, Biscuit Lane",
          address_2: "Westminster",
          town: "London",
          postcode: "SW2 AAA",
          map_east: nil,
          map_north: nil
        )
      end
    end
  end
end
