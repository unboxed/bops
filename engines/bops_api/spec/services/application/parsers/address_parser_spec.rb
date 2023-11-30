# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::AddressParser do
  describe "#parse" do
    let(:parse_address) do
      described_class.new(params).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:property][:address]
      }

      it "returns a correctly formatted address hash" do
        expect(parse_address).to eq(
          uprn: "100021892955",
          address_1: "40, STANSFIELD ROAD",
          address_2: nil,
          town: "LONDON",
          postcode: "SW9 9RZ",
          lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point("-0.1185926", "51.4656522")
        )
      end
    end

    context "with missing longitude and latitude" do
      let(:params) do
        {
          uprn: "123456789",
          pao: "10 Biscuit Lane",
          street: "Westminster",
          organisation: "Bakery",
          town: "London",
          postcode: "SW2 AAA"
        }
      end

      it "returns a hash without lonlat" do
        expect(parse_address).to eq(
          uprn: "123456789",
          address_1: "10 Biscuit Lane, Westminster",
          address_2: "Bakery",
          town: "London",
          postcode: "SW2 AAA",
          lonlat: nil
        )
      end
    end
  end
end
