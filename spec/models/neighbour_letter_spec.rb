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

  context "when setting a resend reason" do
    let(:neighbour) { create(:neighbour) }
    let(:neighbour_letter) { build(:neighbour_letter, neighbour:) }

    context "when sending the first letter to a neighbour" do
      it "must not have a reason" do
        neighbour_letter.resend_reason = "blah blah"
        expect do
          neighbour_letter.save!
        end.to raise_error(ActiveRecord::RecordInvalid)

        neighbour_letter.resend_reason = nil
        expect do
          neighbour_letter.save!
        end.not_to raise_error
      end
    end

    context "when resending a letter to a neighbour" do
      let(:previous_neighbour_letter) { create(:neighbour_letter, neighbour:) }

      before { neighbour.touch(:last_letter_sent_at) }

      it "must have a reason" do
        expect do
          neighbour_letter.save!
        end.to raise_error(ActiveRecord::RecordInvalid)

        neighbour_letter.resend_reason = "blah blah"
        expect do
          neighbour_letter.save!
        end.not_to raise_error
      end
    end
  end
end
