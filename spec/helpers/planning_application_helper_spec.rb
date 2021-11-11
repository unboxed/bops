# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationHelper, type: :helper do
  describe "#map_link" do
    it "returns the correct link for a valid address" do
      expect(map_link("11 Abbey Gardens, London, SE16 3RQ")).to eq("https://google.co.uk/maps/place/11+Abbey+Gardens%2C+London%2C+SE16+3RQ")
    end
  end

  describe "#display_number" do
    it "returns the right number for an element in an array" do
      expect(display_number([25, 84, "proposal", 165, true], 165)).to eq(4)
    end
  end
end
