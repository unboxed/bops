# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteHelper, type: :helper do
  let!(:site) { build(:site, address_1: "5 Radnor Road", town: "London", postcode: "SE15 8UT") }

  describe "correct address" do
    it "constructs the address correctly" do
      expect(display_address(site)).to eq("5 Radnor Road, London, SE15 8UT")
    end
  end
end
