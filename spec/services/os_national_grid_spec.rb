# frozen_string_literal: true

require "rails_helper"

RSpec.describe OsNationalGrid do
  let(:easting) { 481_987.066 }
  let(:northing) { 213_552.27 }
  let(:longitude) { -0.812036 }
  let(:latitude) { 51.814605 }

  describe ".os_ng_to_wgs84" do
    let(:national_grid) do
      described_class.os_ng_to_wgs84(easting, northing)
    end

    it "converts eastings and northings to longitude and latitude" do
      expect(national_grid).to match [
        a_value_within(0.002).of(longitude),
        a_value_within(0.002).of(latitude)
      ]
    end
  end

  describe ".wgs84_to_os_ng" do
    let(:national_grid) do
      described_class.wgs84_to_os_ng(longitude, latitude)
    end

    it "converts longitude and latitude to eastings and northings" do
      expect(national_grid).to match [
        a_value_within(2.0).of(easting),
        a_value_within(2.0).of(northing)
      ]
    end
  end
end
