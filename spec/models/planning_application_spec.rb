# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject { create :planning_application }

  describe "decision validations" do
    let(:assessor)          { build :user, :assessor }
    let(:reviewer)          { build :user, :reviewer }

    let(:decision_associated_with_reviewer) { build :decision, :granted, user: reviewer }
    let(:decision_associated_with_assessor) { build :decision, :granted, user: assessor }

    it "is invalid when an assessor_decision is associated with a non-assessor" do
      subject.assessor_decision = decision_associated_with_reviewer

      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include "Assessor decision cannot be associated with a non-assessor"
    end

    it "is valid when an assessor_decision is associated with an assessor" do
      subject.assessor_decision = decision_associated_with_assessor

      expect(subject).to be_valid
    end

    it "is invalid when a reviewer_decision is associated with a non-reviewer" do
      subject.reviewer_decision = decision_associated_with_assessor

      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include "Reviewer decision cannot be associated with a non-reviewer"
    end

    it "is valid when an reviewer_decision is associated with an reviewer" do
      subject.reviewer_decision = decision_associated_with_reviewer

      expect(subject).to be_valid
    end
  end

  describe "state transitions" do
    let!(:proposed_document_1) do
      create :document, :with_file, :proposed_tags,
             planning_application: subject,
             numbers: "number"
    end

    context "start the application" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("in_assessment_at": 1.hour.ago)
      end

      it "sets the status to in_assessment" do
        subject.update!(documents_validated_at: Time.zone.today)
        subject.start
        expect(subject.status).to eq "in_assessment"
      end

      it "sets the timestamp for in_assessment_at to now" do
        freeze_time do
          subject.update!(documents_validated_at: Time.zone.today)
          subject.start
          expect(subject.send("in_assessment_at")).to eql(Time.current)
        end
      end
    end

    describe "work_status" do
      let!(:proposed_drawing_1) do
        create :document, :with_file, :proposed_tags,
               planning_application: subject,
               numbers: "number"
      end

      subject { create :planning_application, :not_started }

      it "sets work_status to proposed" do
        expect(subject.work_status).to eq "proposed"
      end

      it "allows the work status to be updated" do
        subject.update!(work_status: "existing")
        expect(subject.send("work_status")).to eql("existing")
      end
    end

    context "return the application from invalidated" do
      subject { create :planning_application, :invalidated }

      before do
        # Set timestamp to differentiate from now
        subject.update("returned_at": 1.hour.ago)
      end

      it "sets the status to returned" do
        subject.return
        expect(subject.status).to eq "returned"
      end

      it "sets the timestamp for returned_at to now" do
        freeze_time do
          subject.return
          expect(subject.send("returned_at")).to eql(Time.current)
        end
      end
    end

    context "assess the application" do
      before do
        subject.update("awaiting_determination_at": 1.hour.ago)
      end

      it "sets the status to awaiting_determination" do
        subject.assess
        expect(subject.status).to eq "awaiting_determination"
      end

      it "sets the timestamp for awaiting_determination_at to now" do
        freeze_time do
          subject.assess
          expect(subject.send("awaiting_determination_at")).to eql(Time.current)
        end
      end
    end

    context "invalidate the application from not_started" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        subject.invalidate
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          subject.invalidate
          expect(subject.send("invalidated_at")).to eql(Time.current)
        end
      end
    end

    context "invalidate the application from in_assessment" do
      subject { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        subject.invalidate
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          subject.invalidate
          expect(subject.send("invalidated_at")).to eql(Time.current)
        end
      end
    end

    context "invalidate the application from awaiting_determination" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        subject.invalidate
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          subject.invalidate
          expect(subject.send("invalidated_at")).to eql(Time.current)
        end
      end
    end

    context "sets application to awaiting_correction when request_correction is called" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("awaiting_correction_at": 1.hour.ago)
      end

      it "sets the status to awaiting_correction" do
        subject.request_correction
        expect(subject.status).to eq "awaiting_correction"
      end

      it "sets the timestamp for awaiting_correction to now" do
        freeze_time do
          subject.request_correction
          expect(subject.send("awaiting_correction_at")).to eql(Time.current)
        end
      end
    end

    context "determine the application" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("determined_at": 1.hour.ago)
      end

      it "sets the status to determined" do
        subject.determine
        expect(subject.status).to eq "determined"
      end

      it "sets the timestamp for determined_at to now" do
        freeze_time do
          subject.determine
          expect(subject.send("determined_at")).to eql(Time.current)
        end
      end
    end

    context "withdraw the application from not_started" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        subject.withdraw
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          subject.withdraw
          expect(subject.send("withdrawn_at")).to eql(Time.current)
        end
      end
    end

    context "withdraw the application from in_assessment" do
      subject { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        subject.withdraw
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          subject.withdraw
          expect(subject.send("withdrawn_at")).to eql(Time.current)
        end
      end
    end

    context "withdraw the application from awaiting_determination" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        subject.withdraw
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          subject.withdraw
          expect(subject.send("withdrawn_at")).to eql(Time.current)
        end
      end
    end

    context "withdraw the application from awaiting_correction" do
      subject { create :planning_application, :awaiting_correction }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        subject.withdraw
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          subject.withdraw
          expect(subject.send("withdrawn_at")).to eql(Time.current)
        end
      end
    end
  end

  describe "decisions" do
    let(:assessor)          { create :user, :assessor }
    let(:reviewer)          { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, :granted, user: assessor) }
    let(:reviewer_decision) { create(:decision, :granted, user: reviewer) }

    before do
      subject.decisions << assessor_decision << reviewer_decision
    end

    describe "assessor_decision" do
      it "returns the assessor's decision" do
        expect(subject.reload.assessor_decision).to eq assessor_decision
      end
    end

    describe "reviewer_decision" do
      it "returns the reviewer's decision" do
        expect(subject.reload.reviewer_decision).to eq reviewer_decision
      end
    end
  end

  describe "#reference" do
    it "pads the ID correctly" do
      subject.update(id: 1000)

      expect(subject.reference).to eq "00001000"
    end
  end

  describe "#agent?" do
    it "returns false if no values are given" do
      subject.update(agent_first_name: "", agent_last_name: "", agent_phone: "", agent_email: "")

      expect(subject.reload.agent?).to eq false
    end

    it "returns false if email or phone is not given" do
      subject.update(agent_first_name: "first", agent_last_name: "last", agent_phone: "", agent_email: "")

      expect(subject.agent?).to eq false
    end

    it "returns true if name and email are given" do
      subject.update(agent_first_name: "first", agent_last_name: "last",
                     agent_phone: "", agent_email: "agent@example.com")

      expect(subject.agent?).to eq true
    end

    it "returns true if name and phone are given" do
      subject.update(agent_first_name: "first", agent_last_name: "last",
                     agent_phone: "34433454", agent_email: "")

      expect(subject.agent?).to eq true
    end
  end

  describe "#applicant?" do
    it "returns false if no values are given" do
      subject.update(applicant_first_name: "", applicant_last_name: "",
                     applicant_phone: "", applicant_email: "")

      expect(subject.applicant?).to eq false
    end

    it "returns false if email or phone is not given" do
      subject.update(applicant_first_name: "first", applicant_last_name: "last",
                     applicant_phone: "", applicant_email: "")

      expect(subject.applicant?).to eq false
    end

    it "returns true if name and email are given" do
      subject.update(applicant_first_name: "first", applicant_last_name: "last",
                     applicant_phone: "", applicant_email: "applicant@example.com")

      expect(subject.applicant?).to eq true
    end

    it "returns true if name and phone are given" do
      subject.update(applicant_first_name: "first", applicant_last_name: "last",
                     applicant_phone: "34433454", applicant_email: "")

      expect(subject.applicant?).to eq true
    end
  end

  describe "#documents_ready_for_publication?" do
    let!(:proposed_document_1) do
      create :document, :with_file, :proposed_tags,
            planning_application: subject,
            numbers: "number"
    end

    let!(:existing_document) do
      create :document, :with_file, :existing_tags,
            planning_application: subject
    end

    let!(:archived_document) do
      create :document, :with_file, :proposed_tags, :archived,
            planning_application: subject,
            numbers: "number"
    end

    context "when all proposed, non-archived documents have numbers" do
      it "returns true" do
        expect(subject.documents_ready_for_publication?).to eq true
      end
    end

    context "when there is a proposed, non-archived document without numbers" do
      let!(:proposed_document_2) do
        create :document, :with_file, :proposed_tags,
              planning_application: subject
      end

      it "returns false" do
        expect(subject.documents_ready_for_publication?).to eq false
      end
    end

    context "when there are no documents" do
      before do
        subject.documents.delete_all
      end

      it "returns false" do
        expect(subject.documents_ready_for_publication?).to eq false
      end
    end
  end

  describe "#document_numbering_partially_completed?" do
    it "returns false when there are no documents" do
      expect(subject.document_numbering_partially_completed?).to eq false
    end

    context "when all relevant documents are numbered" do
      let!(:proposed_document_1) do
        create :document, :proposed_tags,
        planning_application: subject,
        numbers: "number"
      end

      it "returns false" do
        expect(subject.document_numbering_partially_completed?).to eq false
      end
    end

    context "when one relevant document has a number and another does not" do
      let!(:proposed_document_1) do
        create :document, :proposed_tags,
        planning_application: subject,
        numbers: "number"
      end

      let!(:proposed_document_2) do
        create :document, :proposed_tags,
        planning_application: subject
      end

      it "returns true" do
        expect(subject.document_numbering_partially_completed?).to eq true
      end
    end
  end
end
