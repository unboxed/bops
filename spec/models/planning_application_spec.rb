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
      create :description_change_validation_request, planning_application: planning_application, state: "open",
                                                     created_at: 12.days.ago
    end

    context "start the application" do
      subject(:planning_application) { create :planning_application, :not_started }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(in_assessment_at: 1.hour.ago)
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
        planning_application.update(returned_at: 1.hour.ago)
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
        planning_application.update(awaiting_determination_at: 1.hour.ago, decision: "granted")
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
        create(
          :additional_document_validation_request,
          planning_application: planning_application,
          state: "pending"
        )
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
        planning_application.update(awaiting_correction_at: 1.hour.ago)
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
        planning_application.update(determined_at: 1.hour.ago)
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
        planning_application.update(withdrawn_at: 1.hour.ago)
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
        planning_application.update(withdrawn_at: 1.hour.ago)
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
        planning_application.update(withdrawn_at: 1.hour.ago)
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
        planning_application.update(withdrawn_at: 1.hour.ago)
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

  describe "deadlines" do
    let(:planning_application) { create(:not_started_planning_application) }
    let(:date) { Time.zone.local(2021, 9, 23, 22, 10, 44) }

    before do
      travel_to date
    end

    describe "#received_at" do
      it "returns the correct business day for the application's created_at" do
        expect(planning_application.received_at).to eq Date.tomorrow
      end
    end

    describe "#target_date" do
      context "when there were no documents validated" do
        before { planning_application.update!(documents_validated_at: nil) }

        it "is set as received at + 35 days" do
          expect(planning_application.target_date).to eq(35.days.after(planning_application.received_at).to_date)
        end
      end

      context "when there are validated documents" do
        before { planning_application.update!(documents_validated_at: 1.week.ago) }

        it "is set to documents_validated_at + 35 days" do
          expect(planning_application.target_date).to eq(35.days.after(planning_application.documents_validated_at).to_date)
        end
      end
    end

    describe "#expiry_date" do
      context "when there were no documents validated" do
        before { planning_application.update!(documents_validated_at: nil) }

        it "is set as received_at + 56 days" do
          expect(planning_application.expiry_date).to eq(56.days.after(planning_application.received_at).to_date)
        end
      end

      context "when there are validated documents" do
        before { planning_application.update!(documents_validated_at: 1.week.ago) }

        it "is set to documents_validated_at + 56 days" do
          planning_application.update!(documents_validated_at: 1.week.ago)
          expect(planning_application.expiry_date).to eq(56.days.after(planning_application.documents_validated_at).to_date)
        end
      end
    end
  end

  describe "#valid_from" do
    let(:planning_application) { create(:not_started_planning_application) }

    context "when the application is not valid" do
      it "is nil" do
        expect(planning_application.valid_from).to be_nil
      end
    end

    context "when the application is valid" do
      context "when there have been validation requests" do
        before do
          [
            [3.days.ago, :closed],
            [2.days.ago, :cancelled],
            [12.days.ago, :closed],
            [1.day.ago, :closed]
          ].each do |at, state|
            create(
              :other_change_validation_request,
              state,
              planning_application: planning_application,
              updated_at: at
            )
          end

          planning_application.start!
        end

        it "is the time of the last successfully closed request" do
          expect(planning_application.valid_from).to eq Time.next_immediate_business_day(1.day.ago)
        end
      end

      context "when there have been no validation requests" do
        before { planning_application.start! }

        it "returns the received_at value" do
          expect(planning_application.valid_from).to eq planning_application.received_at
        end
      end
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

  # rubocop:disable Rails/SkipsModelValidations
  describe "days left/past" do
    let(:planning_application) { create(:planning_application) }

    describe "#days_left" do
      context "when the expiry date is in the future" do
        before { planning_application.update_column(:expiry_date, 3.days.from_now) }

        it "returns a positive number" do
          expect(planning_application.days_left).to be_positive
        end
      end

      context "when the expiry date is past" do
        before { planning_application.update_column(:expiry_date, 12.days.ago) }

        it "returns zero" do
          expect(planning_application.days_left).to eq 0
        end
      end
    end

    describe "#days_overdue" do
      before { travel_to Time.zone.local(2021, 12, 1) }

      context "when the application has not expired" do
        before { planning_application.update_column(:expiry_date, 3.days.from_now) }

        it "returns 0" do
          expect(planning_application.days_overdue).to eq 0
        end
      end

      context "when the application has expired" do
        before { planning_application.update_column(:expiry_date, 3.days.ago) }

        it "returns a positive number" do
          expect(planning_application.days_overdue).to be_positive
        end
      end
    end
  end

  describe "proposal_details" do
    it "defaults to an empty array" do
      planning_application.update!(proposal_details: nil)

      expect(planning_application.proposal_details).to eq []
    end
  end

  describe "flagged_proposal_details" do
    it "returns the relevant questions for the application's result" do
      expect(planning_application.flagged_proposal_details(planning_application.result_flag).length).to eq 1
    end

    context "when there's a proposal detail with multiple responses" do
      before do
        planning_application.proposal_details = File.read("./spec/fixtures/files/multiple_responses_proposal_details.json")
      end

      it "does not crash" do
        expect { planning_application.flagged_proposal_details(planning_application.result_flag) }.not_to raise_error
      end
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  describe "custom_constraints" do
    let(:planning_application) { build(:planning_application) }

    it "contains any custom constraint added" do
      planning_application.constraints << "Foobar"

      expect(planning_application.custom_constraints).to contain_exactly "Foobar"
    end

    it "is empty when all constraints are predefined ones" do
      planning_application.constraints << "Listed Building"

      expect(planning_application.custom_constraints).to be_empty
    end
  end
end
