# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::SubmissionProcessorJob, type: :job do
  let!(:submission) { create(:submission, :planning_portal, status: "started") }

  describe "#perform" do
    context "when everything succeeds" do
      it "processes and completes the submission in order" do
        extractor = instance_double(BopsSubmissions::ZipExtractionService)
        allow(BopsSubmissions::ZipExtractionService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(extractor)
        allow(extractor).to receive(:call)

        creator = instance_double(BopsSubmissions::Application::PlanningPortalCreationService)
        allow(BopsSubmissions::Application::PlanningPortalCreationService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(creator)
        allow(creator).to receive(:call!)

        expect(extractor).to receive(:call).ordered
        expect(creator).to receive(:call!).ordered
        expect(submission).to receive(:complete!).ordered

        described_class.perform_now(submission)
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
        expect {
          described_class.perform_now(submission)
        }.to raise_error(StandardError, "An error!")

        expect(submission.reload.status).to eq("failed")
        expect(submission.error_message).to eq("An error!")
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
        creator = instance_double(BopsSubmissions::Application::PlanningPortalCreationService)
        allow(BopsSubmissions::Application::PlanningPortalCreationService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(creator)
        allow(creator).to receive(:call!).and_raise(ArgumentError, "Submission has no JSON")

        expect {
          described_class.perform_now(submission)
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
        create(:application_type, :minor)

        expect {
          described_class.perform_now(submission)
        }.not_to raise_error

        pa = PlanningApplication.last
        expect(pa).to be_present
        expect(pa.case_record.submission_id).to eq(submission.id)
        expect(pa.local_authority_id).to eq(submission.local_authority_id)
      end
    end

    context "when the submission has an api_user (odp PlanX flow)" do
      let!(:api_user) { create(:api_user, :planx) }
      let!(:odp_submission) do
        create(:submission, status: "started", api_user: api_user, local_authority: api_user.local_authority)
      end

      it "passes submission.api_user as the user to PlanxCreationService" do
        creator = instance_double(BopsSubmissions::Application::PlanxCreationService)
        expect(BopsSubmissions::Application::PlanxCreationService)
          .to receive(:new)
          .with(hash_including(submission: odp_submission, user: api_user))
          .and_return(creator)
        allow(creator).to receive(:call!)

        described_class.perform_now(odp_submission)
      end
    end
  end
end
