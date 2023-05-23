# frozen_string_literal: true

require "rails_helper"

RSpec.describe LetterSendingService do
  let(:letter_sender) { described_class }
  let(:local_authority) { create(:local_authority) }

  describe "#deliver!" do
    let(:user) { create(:user) }

    context "when the request is successful" do
      it "calls send_letter on the notify client and makes a request" do
        notify_request = stub_send_letter(address: "", message: "hello world", status: 200)

        letter_sender.new(local_authority, "", "hello world").deliver!

        expect(notify_request).to have_been_requested
      end
    end
  end
end
