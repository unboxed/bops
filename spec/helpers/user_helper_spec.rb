# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserHelper, type: :helper do
  # subject { build(:agent, first_name: "Annie", last_name: "Khan", postcode: "SE15 8UT", phone: "0789 111111", address_1 "4 Elm Street", town: "London")}
  subject { build(:agent, first_name: "Annie", last_name: "Khan", email: "agent@example.com", phone: "0789 111111") }

  describe "#full_details" do
    it "constructs the personal info correctly" do
      expect(full_details(subject)).to eq("Annie Khan, 0789 111111, agent@example.com")
    end
  end

  describe "#full_name" do
    it "constructs the full name correctly" do
      expect(full_name(subject)).to eq("Annie Khan")
    end
  end
end
