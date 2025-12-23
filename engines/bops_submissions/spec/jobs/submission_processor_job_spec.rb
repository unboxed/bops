# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::SubmissionProcessorJob, type: :job do
  let!(:submission) { create(:submission, :planning_portal, status: "submitted") }

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

        creator = instance_double(BopsSubmissions::Application::PlanningPortalCreationService)
        allow(BopsSubmissions::Application::PlanningPortalCreationService)
          .to receive(:new)
          .with(submission: submission)
          .and_return(creator)
        allow(creator).to receive(:call!)

        expect(submission).to receive(:start!).ordered
        expect(extractor).to receive(:call).ordered
        expect(creator).to receive(:call!).ordered
        expect(submission).to receive(:complete!).ordered

        described_class.perform_now(submission.id, current_api_user: nil)
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
          described_class.perform_now(submission.id, current_api_user: nil)
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
          described_class.perform_now(1, current_api_user: nil)
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
        creator = instance_double(BopsSubmissions::Application::PlanningPortalCreationService)
        allow(BopsSubmissions::Application::PlanningPortalCreationService)
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
          described_class.perform_now(submission.id, current_api_user: nil)
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
          described_class.perform_now(submission.id, current_api_user: nil)
        }.not_to raise_error

        pa = PlanningApplication.last
        expect(pa).to be_present
        expect(pa.case_record.submission_id).to eq(submission.id)
        expect(pa.local_authority_id).to eq(submission.local_authority_id)
      end
    end

    context "when processing an ODP planning application submission" do
      let!(:submission) { create(:submission, :odp_planning_application, status: "submitted") }
      let(:api_user) { create(:api_user, :planx, local_authority: submission.local_authority) }

      before do
        allow(Submission)
          .to receive(:find)
          .with(submission.id)
          .and_return(submission)
      end

      it "calls OdpCreationService with correct params" do
        creator = instance_double(BopsSubmissions::Application::OdpCreationService)
        allow(BopsSubmissions::Application::OdpCreationService)
          .to receive(:new)
          .with(
            submission: submission,
            user: api_user,
            email_sending_permitted: false
          )
          .and_return(creator)
        allow(creator).to receive(:call!)

        expect(submission).to receive(:start!).ordered
        expect(creator).to receive(:call!).ordered
        expect(submission).to receive(:complete!).ordered

        described_class.perform_now(submission.id, api_user)
      end

      context "when metadata.sendEmail is true" do
        let!(:submission) do
          create(:submission, :odp_planning_application, status: "submitted").tap do |s|
            body = s.request_body.dup
            body["metadata"]["sendEmail"] = true
            s.update!(request_body: body)
          end
        end

        it "enables email sending" do
          creator = instance_double(BopsSubmissions::Application::OdpCreationService)
          allow(BopsSubmissions::Application::OdpCreationService)
            .to receive(:new)
            .with(
              submission: submission,
              user: api_user,
              email_sending_permitted: true
            )
            .and_return(creator)
          allow(creator).to receive(:call!)

          described_class.perform_now(submission.id, api_user)
        end
      end

      it "tracks the source correctly" do
        expect(submission.source).to eq("PlanX")
      end

      context "when source is not specified in metadata" do
        let!(:submission) do
          create(:submission, :odp_planning_application, status: "submitted").tap do |s|
            body = s.request_body.dup
            body["metadata"].delete("source")
            s.update!(request_body: body)
          end
        end

        it "defaults source to PlanX" do
          expect(submission.reload.source).to eq("PlanX")
        end
      end

      context "when a custom source is specified" do
        let!(:submission) do
          create(:submission, :odp_planning_application, status: "submitted").tap do |s|
            body = s.request_body.dup
            body["metadata"]["source"] = "CustomPortal"
            s.update!(request_body: body)
          end
        end

        it "uses the custom source" do
          expect(submission.reload.source).to eq("CustomPortal")
        end
      end
    end
  end
end
