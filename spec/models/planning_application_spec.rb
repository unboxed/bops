# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject(:planning_application) { create :planning_application }

  describe "decision validations" do
    let(:assessor)          { build :user, :assessor }
    let(:reviewer)          { build :user, :reviewer }

    let(:decision_associated_with_reviewer) { build :decision, :granted, user: reviewer }
    let(:decision_associated_with_assessor) { build :decision, :granted, user: assessor }

    it "is invalid when an assessor_decision is associated with a non-assessor" do
      planning_application.assessor_decision = decision_associated_with_reviewer

      expect(planning_application).to be_invalid
      expect(planning_application.errors.full_messages).to include "Assessor decision cannot be associated with a non-assessor"
    end

    it "is valid when an assessor_decision is associated with an assessor" do
      planning_application.assessor_decision = decision_associated_with_assessor

      expect(planning_application).to be_valid
    end

    it "is invalid when a reviewer_decision is associated with a non-reviewer" do
      planning_application.reviewer_decision = decision_associated_with_assessor

      expect(planning_application).to be_invalid
      expect(planning_application.errors.full_messages).to include "Reviewer decision cannot be associated with a non-reviewer"
    end

    it "is valid when an reviewer_decision is associated with an reviewer" do
      planning_application.reviewer_decision = decision_associated_with_reviewer

      expect(planning_application).to be_valid
    end
  end

  describe "state transitions" do
    let!(:proposed_document_1) do
      create :document, :with_tags,
             planning_application: planning_application,
             numbers: "number"
    end

    context "start the application" do
      subject(:planning_application) { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("in_assessment_at": 1.hour.ago)
      end

      it "sets the status to in_assessment" do
        planning_application.update!(documents_validated_at: Time.zone.today)
        planning_application.start
        expect(planning_application.status).to eq "in_assessment"
      end

      it "sets the timestamp for in_assessment_at to now" do
        freeze_time do
          planning_application.update!(documents_validated_at: Time.zone.today)
          planning_application.start
          expect(planning_application.send("in_assessment_at")).to eql(Time.zone.now)
        end
      end
    end

    describe "work_status" do
      subject(:planning_application) { create :planning_application, :not_started }

      let!(:proposed_drawing_1) do
        create :document, :with_tags,
               planning_application: planning_application,
               numbers: "number"
      end

      it "sets work_status to proposed" do
        expect(planning_application.work_status).to eq "proposed"
      end

      it "allows the work status to be updated" do
        planning_application.update!(work_status: "existing")
        expect(planning_application.send("work_status")).to eql("existing")
      end
    end

    context "return the application from invalidated" do
      subject(:planning_application) { create :planning_application, :invalidated }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("returned_at": 1.hour.ago)
      end

      it "sets the status to returned" do
        planning_application.return
        expect(planning_application.status).to eq "returned"
      end

      it "sets the timestamp for returned_at to now" do
        freeze_time do
          planning_application.return
          expect(planning_application.send("returned_at")).to eql(Time.zone.now)
        end
      end
    end

    context "assess the application" do
      before do
        planning_application.update("awaiting_determination_at": 1.hour.ago)
      end

      it "sets the status to awaiting_determination" do
        planning_application.assess
        expect(planning_application.status).to eq "awaiting_determination"
      end

      it "sets the timestamp for awaiting_determination_at to now" do
        freeze_time do
          planning_application.assess
          expect(planning_application.send("awaiting_determination_at")).to eql(Time.zone.now)
        end
      end
    end

    context "invalidate the application from not_started" do
      subject(:planning_application) { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        planning_application.invalidate
        expect(planning_application.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          planning_application.invalidate
          expect(planning_application.send("invalidated_at")).to eql(Time.zone.now)
        end
      end
    end

    context "invalidate the application from in_assessment" do
      subject(:planning_application) { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        planning_application.invalidate
        expect(planning_application.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          planning_application.invalidate
          expect(planning_application.send("invalidated_at")).to eql(Time.zone.now)
        end
      end
    end

    context "invalidate the application from awaiting_determination" do
      subject(:planning_application) { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("invalidated_at": 1.hour.ago)
      end

      it "sets the status to invalidated" do
        planning_application.invalidate
        expect(planning_application.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          planning_application.invalidate
          expect(planning_application.send("invalidated_at")).to eql(Time.zone.now)
        end
      end
    end

    context "sets application to awaiting_correction when request_correction is called" do
      subject(:planning_application) { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("awaiting_correction_at": 1.hour.ago)
      end

      it "sets the status to awaiting_correction" do
        planning_application.request_correction
        expect(planning_application.status).to eq "awaiting_correction"
      end

      it "sets the timestamp for awaiting_correction to now" do
        freeze_time do
          planning_application.request_correction
          expect(planning_application.send("awaiting_correction_at")).to eql(Time.zone.now)
        end
      end
    end

    context "determine the application" do
      subject(:planning_application) { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("determined_at": 1.hour.ago)
      end

      it "sets the status to determined" do
        planning_application.determine
        expect(planning_application.status).to eq "determined"
      end

      it "sets the timestamp for determined_at to now" do
        freeze_time do
          planning_application.determine
          expect(planning_application.send("determined_at")).to eql(Time.zone.now)
        end
      end
    end

    context "withdraw the application from not_started" do
      subject(:planning_application) { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw
        expect(planning_application.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.send("withdrawn_at")).to eql(Time.zone.now)
        end
      end
    end

    context "withdraw the application from in_assessment" do
      subject(:planning_application) { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw
        expect(planning_application.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.send("withdrawn_at")).to eql(Time.zone.now)
        end
      end
    end

    context "withdraw the application from awaiting_determination" do
      subject(:planning_application) { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw
        expect(planning_application.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.send("withdrawn_at")).to eql(Time.zone.now)
        end
      end
    end

    context "withdraw the application from awaiting_correction" do
      subject(:planning_application) { create :planning_application, :awaiting_correction }

      before do
        # Set timestamp to differentiate from now
        planning_application.update("withdrawn_at": 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw
        expect(planning_application.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.send("withdrawn_at")).to eql(Time.zone.now)
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
      planning_application.decisions << assessor_decision << reviewer_decision
    end

    describe "assessor_decision" do
      it "returns the assessor's decision" do
        expect(planning_application.reload.assessor_decision).to eq assessor_decision
      end
    end

    describe "reviewer_decision" do
      it "returns the reviewer's decision" do
        expect(planning_application.reload.reviewer_decision).to eq reviewer_decision
      end
    end
  end

  describe "#reference" do
    it "pads the ID correctly" do
      planning_application.update!(id: 1000)

      expect(planning_application.reference).to eq "00001000"
    end
  end

  describe "#agent?" do
    it "returns false if no values are given" do
      planning_application.update!(agent_first_name: "", agent_last_name: "", agent_phone: "", agent_email: "")

      expect(planning_application.reload.agent?).to eq false
    end

    it "returns false if email or phone is not given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last", agent_phone: "", agent_email: "")

      expect(planning_application.agent?).to eq false
    end

    it "returns true if name and email are given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last",
                                   agent_phone: "", agent_email: "agent@example.com")

      expect(planning_application.agent?).to eq true
    end

    it "returns true if name and phone are given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last",
                                   agent_phone: "34433454", agent_email: "")

      expect(planning_application.agent?).to eq true
    end
  end

  describe "#applicant?" do
    it "returns false if no values are given" do
      planning_application.update!(applicant_first_name: "", applicant_last_name: "",
                                   applicant_phone: "", applicant_email: "")

      expect(planning_application.applicant?).to eq false
    end

    it "returns false if email or phone is not given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
                                   applicant_phone: "", applicant_email: "")

      expect(planning_application.applicant?).to eq false
    end

    it "returns true if name and email are given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
                                   applicant_phone: "", applicant_email: "applicant@example.com")

      expect(planning_application.applicant?).to eq true
    end

    it "returns true if name and phone are given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
                                   applicant_phone: "34433454", applicant_email: "")

      expect(planning_application.applicant?).to eq true
    end
  end

  describe "#target_date" do
    it "is set as created_at + 8 weeks when new record created" do
      planning_application = create(:planning_application)
      expect(planning_application.target_date).to eq((planning_application.created_at + 8.weeks).to_date)
    end

    it "is set to documents_validated_at + 8 weeks when documents_validated_at added" do
      planning_application = create(:planning_application)
      planning_application.update!(documents_validated_at: 1.week.ago)
      expect(planning_application.target_date).to eq((planning_application.documents_validated_at + 8.weeks).to_date)
    end
  end
end
