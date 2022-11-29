# frozen_string_literal: true

require "rails_helper"

RSpec.describe Note do
  describe "validations" do
    subject(:note) { described_class.new }

    describe "#entry" do
      it "validates presence" do
        expect { note.valid? }.to change { note.errors[:entry] }.to ["can't be blank"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect { note.valid? }.to change { note.errors[:user] }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { note.valid? }.to change { note.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:notes1) { create(:note, created_at: Time.zone.now - 1.day) }
      let!(:notes2) { create(:note, created_at: Time.zone.now) }
      let!(:notes3) { create(:note, created_at: Time.zone.now - 2.days) }

      it "returns notes sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([notes2, notes1, notes3])
      end
    end
  end
end
