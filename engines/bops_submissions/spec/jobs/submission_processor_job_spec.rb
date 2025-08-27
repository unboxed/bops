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

        creator = instance_double(BopsSubmissions::Application::CreationService)
        allow(BopsSubmissions::Application::CreationService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(creator)
        allow(creator).to receive(:call!)

        expect(submission).to receive(:start!).ordered
        expect(extractor).to receive(:call).ordered
        expect(creator).to receive(:call!).ordered
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

    context "when the submission cannot be found" do
      before do
        allow(Submission).to receive(:find).with(1).and_raise(ActiveRecord::RecordNotFound.new("not found"))
        allow(Appsignal).to receive(:report_error)
      end

      it "reports the RecordNotFound to AppSignal and re-raises" do
        expect(Appsignal).to receive(:report_error).with(instance_of(ActiveRecord::RecordNotFound))

        expect {
          described_class.perform_now(1)
        }.to raise_error(ActiveRecord::RecordNotFound, "not found")
      end
    end

    context "when creation fails due to missing JSON" do
      let(:extractor) { instance_double(BopsSubmissions::ZipExtractionService) }

      before do
        allow(BopsSubmissions::ZipExtractionService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(extractor)
        allow(extractor).to receive(:call)
      end

      it "raises ArgumentError and fails the submission" do
        creator = instance_double(BopsSubmissions::Application::CreationService)
        allow(BopsSubmissions::Application::CreationService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(creator)
        allow(creator).to receive(:call!).and_raise(ArgumentError, "Submission has no JSON")

        expect(submission).to receive(:start!).ordered
        expect(extractor).to receive(:call).ordered
        expect(creator).to receive(:call!).ordered
        expect(submission).to receive(:fail!).ordered.and_call_original
        expect(submission).to receive(:update!).with(error_message: "Submission has no JSON").ordered.and_call_original

        expect {
          described_class.perform_now(submission.id)
        }.to raise_error(ArgumentError, "Submission has no JSON")

        expect(submission.reload.status).to eq("failed")
        expect(submission.error_message).to eq("Submission has no JSON")
      end
    end

    context "when creation succeeds and a PlanningApplication is saved" do
      let(:extractor) { instance_double(BopsSubmissions::ZipExtractionService) }

      before do
        allow(BopsSubmissions::ZipExtractionService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(extractor)
        allow(extractor).to receive(:call)

        json_data = json_fixture_submissions("files/applications/PT-10087984.json")
        submission.update!(json_file: json_data)
      end

      it "creates a PlanningApplication record" do
        create(:application_type, :planning_permission)

        expect {
          described_class.perform_now(submission.id)
        }.not_to raise_error

        pa = PlanningApplication.last
        expect(pa).to be_present
        expect(pa.case_record.submission_id).to eq(submission.id)
        expect(pa.local_authority_id).to eq(submission.local_authority_id)
      end
    end
  end
end
