# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject(:planning_application) { create :planning_application }

  describe "callbacks" do
    describe "::after_create" do
      context "when there is a postcode set" do
        let(:planning_application) { create :planning_application, postcode: "SE22 0HW" }

        it "calls the mapit API and sets the ward information" do
          expect_any_instance_of(Apis::Mapit::Client).to receive(:call).with("SE22 0HW").and_call_original

          expect(planning_application.ward).to eq("South Bermondsey")
          expect(planning_application.ward_type).to eq("London borough ward")
        end
      end

      context "when there is no postcode set" do
        let(:planning_application) { create :planning_application, postcode: nil }

        it "does not call the mapit API" do
          expect_any_instance_of(Apis::Mapit::Client).not_to receive(:call)

          expect(planning_application.ward).to eq(nil)
          expect(planning_application.ward_type).to eq(nil)
        end
      end
    end
  end

  describe "#reference" do
    it "starts with 0 and then the planning_application ID" do
      expect(planning_application.reference).to match(/^(?:0+#{planning_application.id})$/)
    end

    it "has 8 characters length" do
      expect(planning_application.reference).to match(/^\d{8}$/)
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

  describe "#submit_recommendation!" do
    let(:planning_application) { create(:planning_application, :in_assessment, decision: "granted") }
    let(:recommendation) { create(:recommendation, planning_application: planning_application, submitted: "false") }
    let(:user) { create(:user) }

    before do
      freeze_time
      planning_application.recommendations << recommendation
      Current.user = user
    end

    describe "when successful" do
      it "submits the recommendation and creates an audit record" do
        expect { planning_application.submit_recommendation! }
          .to change(planning_application, :status).from("in_assessment").to("awaiting_determination")
                                                   .and change(planning_application.recommendations.reload.last, :submitted).from(false).to(true)

        expect(planning_application.awaiting_determination_at).to eq(Time.current)

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "submitted",
          user: user
        )
      end
    end

    describe "when there is an error" do
      it "when planning application does not have status in_assessment it raises PlanningApplication::SubmitRecommendationError" do
        planning_application.update(status: "awaiting_determination")

        expect { planning_application.submit_recommendation! }
          .to raise_error(PlanningApplication::SubmitRecommendationError, "Event 'submit' cannot transition from 'awaiting_determination'.")
          .and change(Audit, :count).by(0)

        expect(planning_application).to be_awaiting_determination
      end
    end
  end

  describe "#withdraw_last_recommendation!" do
    let(:planning_application) { create(:submitted_planning_application) }
    let(:user) { create(:user) }

    before do
      freeze_time
      Current.user = user
    end

    describe "when successful" do
      it "withdraws the recommendation and creates an audit record" do
        expect { planning_application.withdraw_last_recommendation! }
          .to change(planning_application, :status).from("awaiting_determination").to("in_assessment")
                                                   .and change(planning_application.recommendations.reload.last, :submitted).from(true).to(false)

        expect(planning_application.in_assessment_at).to eq(Time.current)

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "withdrawn_recommendation",
          user: user
        )
      end
    end

    describe "when there is an error" do
      it "when planning application is not in awaiting_determination it raises PlanningApplication::WithdrawRecommendationError" do
        planning_application.update(status: "determined")

        expect { planning_application.withdraw_last_recommendation! }
          .to raise_error(PlanningApplication::WithdrawRecommendationError, "Event 'withdraw_recommendation' cannot transition from 'determined'.")
          .and change(Audit, :count).by(0)

        expect(planning_application).to be_determined
      end
    end
  end
end
