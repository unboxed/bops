# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::SubmissionProcessorJob, type: :job do
  let!(:submission) { create(:submission, status: "submitted") }

  before do
    allow(Submission)
      .to receive(:find)
      .with(submission.id)
      .and_return(submission)
  end

  describe "#perform" do
    context "when everything succeeds" do
      it "starts, processes, and completes the submission in order" do
        extractor = instance_double(BopsSubmissions::ZipExtractionService)
        allow(BopsSubmissions::ZipExtractionService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(extractor)
        allow(extractor).to receive(:call)

        expect(submission).to receive(:start!).ordered
        expect(extractor).to receive(:call).ordered
        expect(submission).to receive(:complete!).ordered

        described_class.perform_now(submission.id)
      end
    end

    context "when the extractor raises" do
      let(:error) { StandardError.new("An error!") }
      before do
        extractor = instance_double(BopsSubmissions::ZipExtractionService)
        allow(BopsSubmissions::ZipExtractionService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(extractor)
        allow(extractor).to receive(:call).and_raise(error)
      end

      it "calls start!, then fail!, updates the error, and re-raises" do
        expect(submission).to receive(:start!).ordered.and_call_original
        expect(submission).to receive(:fail!).ordered.and_call_original
        expect(submission).to receive(:update!).with(error_message: "An error!").ordered.and_call_original

        expect {
          described_class.perform_now(submission.id)
        }.to raise_error(StandardError, "An error!")

        expect(submission.reload.status).to eq("failed")
        expect(submission.error_message).to eq("An error!")
      end
    end
  end
end
