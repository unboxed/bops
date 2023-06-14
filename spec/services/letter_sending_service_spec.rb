# frozen_string_literal: true

require "rails_helper"

RSpec.describe LetterSendingService do
  let(:letter_sender) { described_class }
  let(:neighbour) { create(:neighbour) }

  describe "#deliver!" do
    let(:user) { create(:user) }

    context "when the request is successful" do
      let(:status) { 200 }

      before do
        travel_to(DateTime.new(2023, 1, 5, 5))
      end

      it "makes a request and records it in the model" do
        notify_request = stub_send_letter(message: "hello world", status: 200)
        letter_sender.new(neighbour, "hello world").deliver!

        expect(notify_request).to have_been_requested

        letter = NeighbourLetter.last
        expect(letter.neighbour).to eq neighbour
        expect(letter.notify_response).not_to be_nil
        expect(letter.sent_at).not_to be_nil
        expect(letter.id).not_to be_nil
        expect(letter.status).not_to be_nil
        expect(neighbour.consultation.end_date).to eq(DateTime.new(2023, 1, 27, 9))
        expect(neighbour.consultation.start_date).to eq(DateTime.new(2023, 1, 6, 9))
      end
    end

    context "when the request is unsuccessful" do
      let(:status) { 500 }

      it "makes a request but does not record a sending date" do
        expect(Appsignal).to receive(:send_error)

        notify_request = stub_send_letter(message: "hello world", status:)
        letter_sender.new(neighbour, "hello world").deliver!

        expect(notify_request).to have_been_requested

        letter = NeighbourLetter.last
        expect(letter.neighbour).to eq neighbour
        expect(letter.notify_response).to be_nil
        expect(letter.sent_at).to be_nil
        expect(letter.status).to eq("rejected")
        expect(letter.failure_reason).to eq("Exception: Internal server error")
      end
    end
  end
end
