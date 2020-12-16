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
    let!(:proposed_drawing_1) do
      create :drawing, :with_plan, :proposed_tags,
             planning_application: subject,
             numbers: "number"
    end

    context "start the application" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("in_assessment_at": 1.hour.ago)

        subject.start
      end

      it "sets the status to in_assessment" do
        expect(subject.status).to eq "in_assessment"
      end

      it "sets the timestamp for in_assessment_at to now" do
        expect(subject.send("in_assessment_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "return the application from invalidated" do
      subject { create :planning_application, :invalidated }

      before do
        # Set timestamp to differentiate from now
        subject.update("returned_at": 1.hour.ago)

        subject.return
      end

      it "sets the status to returned" do
        expect(subject.status).to eq "returned"
      end

      it "sets the timestamp for returned_at to now" do
        expect(subject.send("returned_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "assess the application" do
      before do
        subject.update("awaiting_determination_at": 1.hour.ago)

        subject.assess
      end

      it "sets the status to awaiting_determination" do
        expect(subject.status).to eq "awaiting_determination"
      end

      it "sets the timestamp for awaiting_determination_at to now" do
        expect(subject.send("awaiting_determination_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "invalidate the application from not_started" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)

        subject.invalidate
      end

      it "sets the status to invalidated" do
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        expect(subject.send("invalidated_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "invalidate the application from in_assessment" do
      subject { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)

        subject.invalidate
      end

      it "sets the status to invalidated" do
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        expect(subject.send("invalidated_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "invalidate the application from awaiting_determination" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("invalidated_at": 1.hour.ago)

        subject.invalidate
      end

      it "sets the status to invalidated" do
        expect(subject.status).to eq "invalidated"
      end

      it "sets the timestamp for invalidated_at to now" do
        expect(subject.send("invalidated_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "sets application to awaiting_correction when request_correction is called" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("awaiting_correction_at": 1.hour.ago)

        subject.request_correction
      end

      it "sets the status to awaiting_correction" do
        expect(subject.status).to eq "awaiting_correction"
      end

      it "sets the timestamp for awaiting_correction to now" do
        expect(subject.send("awaiting_correction_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "determine the application" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("determined_at": 1.hour.ago)

        subject.determine
      end

      it "sets the status to determined" do
        expect(subject.status).to eq "determined"
      end

      it "sets the timestamp for determined_at to now" do
        expect(subject.send("determined_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "withdraw the application from not_started" do
      subject { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)

        subject.withdraw
      end

      it "sets the status to withdrawn" do
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        expect(subject.send("withdrawn_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "withdraw the application from in_assessment" do
      subject { create :planning_application }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)

        subject.withdraw
      end

      it "sets the status to withdrawn" do
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        expect(subject.send("withdrawn_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "withdraw the application from awaiting_determination" do
      subject { create :planning_application, :awaiting_determination }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)

        subject.withdraw
      end

      it "sets the status to withdrawn" do
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        expect(subject.send("withdrawn_at")).to be_within(1.second).of(Time.current)
      end
    end

    context "withdraw the application from awaiting_correction" do
      subject { create :planning_application, :awaiting_correction }

      before do
        # Set timestamp to differentiate from now
        subject.update("withdrawn_at": 1.hour.ago)

        subject.withdraw
      end

      it "sets the status to withdrawn" do
        expect(subject.status).to eq "withdrawn"
      end

      it "sets the timestamp for withdrawn_at to now" do
        expect(subject.send("withdrawn_at")).to be_within(1.second).of(Time.current)
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

  describe "#drawings_ready_for_publication?" do
    let!(:proposed_drawing_1) do
      create :drawing, :with_plan, :proposed_tags,
            planning_application: subject,
            numbers: "number"
    end

    let!(:existing_drawing) do
      create :drawing, :with_plan, :existing_tags,
            planning_application: subject
    end

    let!(:archived_drawing) do
      create :drawing, :with_plan, :proposed_tags, :archived,
            planning_application: subject,
            numbers: "number"
    end

    context "when all proposed, non-archived drawings have numbers" do
      it "returns true" do
        expect(subject.drawings_ready_for_publication?).to eq true
      end
    end

    context "when there is a proposed, non-archived drawing without numbers" do
      let!(:proposed_drawing_2) do
        create :drawing, :with_plan, :proposed_tags,
              planning_application: subject
      end

      it "returns false" do
        expect(subject.drawings_ready_for_publication?).to eq false
      end
    end

    context "when there are no drawings" do
      before do
        subject.drawings.delete_all
      end

      it "returns false" do
        expect(subject.drawings_ready_for_publication?).to eq false
      end
    end
  end

  describe "#drawing_numbering_partially_completed?" do
    it "returns false when there are no drawings" do
      expect(subject.drawing_numbering_partially_completed?).to eq false
    end

    context "when all relevant drawings are numbered" do
      let!(:proposed_drawing_1) do
        create :drawing, :proposed_tags,
        planning_application: subject,
        numbers: "number"
      end

      it "returns false" do
        expect(subject.drawing_numbering_partially_completed?).to eq false
      end
    end

    context "when one relevant drawing has a number and another does not" do
      let!(:proposed_drawing_1) do
        create :drawing, :proposed_tags,
        planning_application: subject,
        numbers: "number"
      end

      let!(:proposed_drawing_2) do
        create :drawing, :proposed_tags,
        planning_application: subject
      end

      it "returns true" do
        expect(subject.drawing_numbering_partially_completed?).to eq true
      end
    end
  end
end
