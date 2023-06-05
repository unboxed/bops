# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourLetter do
  describe "#valid?" do
    let(:neighbour_letter) { build(:neighbour_letter) }

    it "is true for factory" do
      expect(neighbour_letter.valid?).to be(true)
    end
  end

  describe "#update_status" do
    let(:neighbour_letter) { create(:neighbour_letter, notify_id: "123") }

    it "updates the letter's status from notify" do
      notify_request = stub_get_notify_status(notify_id: neighbour_letter.notify_id)

      neighbour_letter.update_status
      expect(notify_request).to have_been_requested

      expect(neighbour_letter.status).to eq("received")
    end
  end
end
