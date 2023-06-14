# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consultation do
  describe "#valid?" do
    let(:consultation) { build(:consultation) }

    it "is true for factory" do
      expect(consultation.valid?).to be(true)
    end
  end

  describe "#end_date_from_now" do
    let(:consultation) { create(:consultation) }

    before do
      travel_to date
    end

    context "when tomorrow is not a working day" do
      context "when it is saturday" do
        # Sat, 23 Sep 2023 13:00:00
        let(:date) { Time.zone.local(2023, 9, 23, 13) }

        it "returns the day 21 days after the next working day" do
          expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 17, 9))
        end
      end

      context "when it is sunday" do
        # Sun, 24 Sep 2023 13:00:00
        let(:date) { Time.zone.local(2023, 9, 24, 13) }

        it "returns the day 21 days after the next working day" do
          expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 17, 9))
        end
      end
    end

    context "when tomorrow is a working day" do
      # Wed, 20 Sep 2023 13:00:00
      let(:date) { Time.zone.local(2023, 9, 20, 13) }

      it "returns the day 21 days after the next working day" do
        expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 12, 13))
      end
    end
  end
end
