# frozen_string_literal: true

require "rails_helper"

RSpec.describe LetterSendingService do
  let(:letter_sender) { described_class }
  let(:neighbour) { create(:neighbour) }

  describe "#deliver!" do
    let(:user) { create(:user) }

    context "when the request is successful" do
      let(:status) { 200 }

      it "makes a request and records it in the model" do
        notify_request = stub_send_letter(neighbour:, message: "hello world", status: 200)
        letter_sender.new(neighbour, "hello world").deliver!

        expect(notify_request).to have_been_requested

        letter = NeighbourLetter.last
        expect(letter.neighbour).to eq neighbour
        expect(letter.notify_response).not_to be_nil
        expect(letter.sent_at).not_to be_nil
        expect(letter.id).not_to be_nil
        expect(letter.status).not_to be_nil
      end
    end

    context "when the request is unsuccessful" do
      let(:status) { 500 }

      it "makes a request but does not record a sending date" do
        notify_request = stub_send_letter(neighbour:, message: "hello world", status:)
        letter_sender.new(neighbour, "hello world").deliver!

        expect(notify_request).to have_been_requested

        letter = NeighbourLetter.last
        expect(letter.neighbour).to eq neighbour
        expect(letter.notify_response).to be_nil
        expect(letter.sent_at).to be_nil
        expect(letter.status).to eq("rejected")
      end
    end
  end
end