# frozen_string_literal: true

require "rails_helper"

RSpec.describe LetterSendingService do
  let!(:planning_application) { create(:planning_application, :planning_permission) }
  let(:neighbour) { create(:neighbour, consultation: planning_application.consultation) }
  let(:letter_sender) { described_class }

  describe "#deliver!" do
    let(:user) { create(:user) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")
    end

    context "when the request is successful" do
      let(:status) { 200 }

      before do
        travel_to(Time.utc(2023, 1, 5, 5))
      end

      it "makes a request and records it in the model" do
        letter_content = "Application received: #{neighbour.consultation.planning_application.received_at.to_fs(:day_month_year_slashes)}"
        notify_request = stub_send_letter(status: 200)
        letter_sender.new(neighbour, letter_content).deliver!

        expect(notify_request).to have_been_requested

        letter = NeighbourLetter.last
        expect(letter.neighbour).to eq neighbour
        expect(letter.notify_response).not_to be_nil
        expect(letter.sent_at).not_to be_nil
        expect(letter.id).not_to be_nil
        expect(letter.status).not_to be_nil
        expect(neighbour.consultation.end_date).to eq(Time.utc(2023, 1, 27).to_date)
        expect(neighbour.consultation.start_date).to eq(Time.utc(2023, 1, 6).to_date)
        expect(letter.text).to include(letter_content)
      end
    end

    context "when the request is unsuccessful" do
      let(:status) { 500 }

      it "makes a request but does not record a sending date" do
        expect(Appsignal).to receive(:send_error)

        notify_request = stub_send_letter(status:)
        letter_sender.new(neighbour, "Hi").deliver!

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
