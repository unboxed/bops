# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bops::Holidays do
  describe "#holidays" do
    let(:start_date) { Date.new(2024, 8, 15) }
    before do
      travel_to(start_date)
    end

    it "returns an array of dates" do
      expect(Bops::Holidays.holidays.first).to eq(Time.zone.local(2024, 8, 26).to_date)
    end
  end

  describe "#date_range_plus_holidays" do
    it "returns the date N days after the given day" do
      from_date = Time.zone.local(2024, 7, 1)
      expect(Bops::Holidays.days_after_plus_holidays(from_date: from_date, count: 21)).to eq(Time.zone.local(2024, 7, 22))
    end

    it "returns additional days if there is a bank holiday in the given range" do
      from_date = Time.zone.local(2024, 8, 15)
      expect(Bops::Holidays.days_after_plus_holidays(from_date: from_date, count: 21)).to eq(Time.zone.local(2024, 9, 6))
    end
  end
end
