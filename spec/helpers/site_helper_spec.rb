# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiteHelper, type: :helper do
  subject { create :site }

  describe "correct address" do
    it "constructs the address correctly" do
      expect(display_address(subject)).to eq("#{subject.address_1}, #{subject.town}, #{subject.postcode}")
    end
  end
end
