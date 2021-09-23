# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject(:planning_application) { create :planning_application }

  describe "state transitions" do
    let!(:proposed_document_1) do
      create :document, :with_tags,
             planning_application: planning_application,
             numbers: "number"
    end

    let!(:description_change_validation_request) do
      create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago
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
        planning_application.update("awaiting_determination_at": 1.hour.ago, decision: "granted")
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

    context "sets application to awaiting_correction when request_correction is called" do
      subject(:planning_application) { create :planning_application, :awaiting_determination, decision: "granted" }

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
      subject(:planning_application) { create :planning_application, :awaiting_determination, decision: "granted" }

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
      subject(:planning_application) { create :planning_application, :awaiting_determination, decision: "granted" }

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
      subject(:planning_application) { create :planning_application, :awaiting_correction, decision: "granted" }

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

    it "returns true if only name is given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last", agent_phone: "", agent_email: "")

      expect(planning_application.agent?).to eq true
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

    it "returns true if only name is given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
                                   applicant_phone: "", applicant_email: "")

      expect(planning_application.applicant?).to eq true
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
    before do
      travel_to Time.zone.local(2021, 9, 23, 10, 10, 44)
      create :planning_application
    end

    it "is set as created_at + 35 business days when new record created" do
      expect(planning_application.target_date).to eq(35.business_days.after(planning_application.created_at).to_date)
    end

    it "is set to documents_validated_at + 35 business days when documents_validated_at added" do
      planning_application.update!(documents_validated_at: 1.week.ago)
      expect(planning_application.target_date).to eq(35.business_days.after(planning_application.documents_validated_at).to_date)
    end
  end

  describe "#expiry_date" do
    it "is set as created_at + 40 business days when new record created" do
      expect(planning_application.expiry_date).to eq(40.business_days.after(planning_application.created_at).to_date)
    end

    it "is set to documents_validated_at + 40 business days when documents_validated_at added" do
      planning_application.update!(documents_validated_at: 1.week.ago)
      expect(planning_application.expiry_date).to eq(40.business_days.after(planning_application.documents_validated_at).to_date)
    end
  end

  describe "parsed_application_type" do
    subject(:planning_application) { create :planning_application }

    it "correctly returns the application type for lawfulness certificate" do
      expect(planning_application.parsed_application_type).to eq "Certificate of Lawfulness"
    end

    it "correctly returns the application type for full" do
      planning_application.update!(application_type: "full")
      expect(planning_application.parsed_application_type).to eql("Full")
    end
  end

  describe "policy_classes" do
    context "when the application is not assessable anymore" do
      let(:planning_application) { create(:planning_application, :determined) }
      let(:policy_class) { build(:policy_class) }

      before do
        policy_class.stamp_part!(1)
      end

      it "is invalid" do
        planning_application.policy_classes += [policy_class]

        expect(planning_application).not_to be_valid
      end
    end
  end
end
