# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::AddressParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_address) do
      described_class.new(params, local_authority:).parse
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
          latitude: 51.4656522,
          longitude: -0.1185926
        )
      end
    end

    context "with a sao param" do
      let(:params) do
        {
          uprn: "123456789",
          sao: "Flat 1",
          pao: "10 Biscuit Lane",
          street: "Westminster",
          organisation: "Bakery",
          town: "London",
          postcode: "SW2 AAA"
        }
      end

      it "returns a correctly formatted address hash" do
        expect(parse_address).to match(a_hash_including(
          address_1: "Flat 1, 10 Biscuit Lane, Westminster"
        ))
      end
    end

    context "with a saoEnd param" do
      let(:params) do
        {
          uprn: "123456789",
          sao: "Flat 1",
          saoEnd: "10",
          pao: "10 Biscuit Lane",
          street: "Westminster",
          organisation: "Bakery",
          town: "London",
          postcode: "SW2 AAA"
        }
      end

      it "returns a correctly formatted address hash" do
        expect(parse_address).to match(a_hash_including(
          address_1: "Flat 1–10, 10 Biscuit Lane, Westminster"
        ))
      end
    end

    context "with a paoEnd param" do
      let(:params) do
        {
          uprn: "123456789",
          pao: "1",
          paoEnd: "10 Biscuit Lane",
          street: "Westminster",
          organisation: "Bakery",
          town: "London",
          postcode: "SW2 AAA"
        }
      end

      it "returns a correctly formatted address hash" do
        expect(parse_address).to match(a_hash_including(
          address_1: "1–10 Biscuit Lane, Westminster"
        ))
      end
    end

    context "with a saoEnd and paoEnd param" do
      let(:params) do
        {
          uprn: "123456789",
          sao: "Flat 1",
          saoEnd: "10",
          pao: "10",
          paoEnd: "12 Biscuit Lane",
          street: "Westminster",
          organisation: "Bakery",
          town: "London",
          postcode: "SW2 AAA"
        }
      end

      it "returns a correctly formatted address hash" do
        expect(parse_address).to match(a_hash_including(
          address_1: "Flat 1–10, 10–12 Biscuit Lane, Westminster"
        ))
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
          longitude: nil,
          latitude: nil
        )
      end
    end
  end
end
