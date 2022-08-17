# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject(:planning_application) { create :planning_application }

  it_behaves_like("Auditable") do
    let(:subject) { create(:planning_application) }
  end

  describe "validations" do
    describe "#determination_date" do
      it "validates that date is not in the future" do
        planning_application = build(:planning_application, determination_date: Time.current + 1.day)

        expect do
          planning_application.valid?
        end.to change {
          planning_application.errors[:determination_date]
        }.to ["Determination date must be today or in the past"]
      end

      it "does not raise a validation error if date is today" do
        planning_application = build(:planning_application, determination_date: Time.current)

        expect { planning_application.valid? }.not_to(change { planning_application.errors[:determination_date] })
      end

      it "does not raise a validation error if date is in the past" do
        planning_application = build(:planning_application, determination_date: Time.current - 1.day)

        expect { planning_application.valid? }.not_to(change { planning_application.errors[:determination_date] })
      end
    end

    describe "#payment_amount" do
      it "validates that it must be greater than or equal to 0" do
        planning_application = build(:planning_application, payment_amount: -1)

        expect { planning_application.valid? }.to change { planning_application.errors[:payment_amount] }.to ["Payment amount (£) must be greater than or equal to 0"]
      end

      it "validates that it must be a number" do
        planning_application = build(:planning_application, payment_amount: "n")

        expect { planning_application.valid? }.to change { planning_application.errors[:payment_amount] }.to ["Payment amount must be a number not exceeding 2 decimal places"]
      end

      it "does not raise a validation error if value is 0" do
        planning_application = build(:planning_application, payment_amount: 0)

        expect { planning_application.valid? }.not_to(change { planning_application.errors[:payment_amount] })
      end

      it "does not raise a validation error if value is a decimal" do
        planning_application = build(:planning_application, payment_amount: 12.43)

        expect { planning_application.valid? }.not_to(change { planning_application.errors[:payment_amount] })
      end
    end
  end

  describe "associations" do
    describe "fee_validation_requests" do
      let!(:planning_application) { create(:planning_application, :invalidated) }
      let!(:other_change_validation_request1) do
        create(:other_change_validation_request, fee_item: false, planning_application: planning_application)
      end
      let!(:other_change_validation_request2) do
        create(:other_change_validation_request, fee_item: true, planning_application: planning_application)
      end

      it "returns a has many association only where fee item is set to true on other change validation requests" do
        expect(planning_application.fee_item_validation_requests).to eq([other_change_validation_request2])
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:planning_application1) { create(:planning_application, created_at: Time.zone.now - 1.day) }
      let!(:planning_application2) { create(:planning_application, created_at: Time.zone.now) }
      let!(:planning_application3) { create(:planning_application, created_at: Time.zone.now - 2.days) }

      it "returns planning applications sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([planning_application2, planning_application1, planning_application3])
      end
    end

    describe ".for_user_and_null_users" do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let!(:planning_application1) { create(:planning_application, user: user1) }
      let!(:planning_application2) { create(:planning_application, user: user2) }
      let!(:planning_application3) { create(:planning_application, user: nil) }

      it "returns planning applications for a given user_id and all other null users" do
        expect(described_class.for_user_and_null_users(user1.id)).to match_array(
          [planning_application1, planning_application3]
        )
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #set_application_number" do
      context "when an application number for a given local authority already exists" do
        let(:local_authority) { create :local_authority }
        let!(:planning_application) { create :planning_application, local_authority: local_authority }

        before do
          allow_any_instance_of(described_class).to receive(:set_application_number).and_return(planning_application.application_number)
        end

        it "raises a non unique error" do
          expect do
            create :planning_application, local_authority: local_authority, application_number: 100
          end.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end

      context "when application number is unique for the local authority" do
        let(:local_authority1) { create(:local_authority, :southwark) }
        let(:local_authority2) { create(:local_authority, :lambeth) }

        let(:planning_application1) do
          create(:planning_application, local_authority: local_authority1)
        end

        let(:planning_application2) do
          create(:planning_application, local_authority: local_authority1)
        end

        let(:planning_application3) do
          create(:planning_application, local_authority: local_authority2)
        end

        it "updates application number successfully" do
          expect(planning_application1.application_number).to eq("00100")
          expect(planning_application2.application_number).to eq("00101")
          expect(planning_application3.application_number).to eq("00100")
        end
      end

      context "when a planning application is deleted" do
        let(:local_authority) { create :local_authority }
        let(:planning_application1) { create :planning_application, local_authority: local_authority }
        let(:planning_application2) { create :planning_application, local_authority: local_authority }
        let(:planning_application3) { create :planning_application, local_authority: local_authority }
        let(:planning_application4) { create :planning_application, local_authority: local_authority }

        it "updates the application number incrementing after the existing maximum application number" do
          expect(planning_application1.application_number).to eq("00100")
          expect(planning_application2.application_number).to eq("00101")
          expect(planning_application3.application_number).to eq("00102")

          planning_application2.destroy

          expect(planning_application4.application_number).to eq("00103")
        end
      end

      describe "#reference" do
        let(:planning_application) do
          build(:planning_application, work_status: "proposed")
        end

        it "is set when application is created" do
          travel_to(DateTime.new(2022, 1, 1)) do
            expect { planning_application.save }
              .to change(planning_application, :reference)
              .from(nil)
              .to("22-00100-LDCP")
          end
        end
      end
    end

    describe "::after_create" do
      context "when there is a postcode set" do
        let(:planning_application) { create :planning_application, postcode: "SE22 0HW" }

        it "calls the mapit API and sets the ward information" do
          expect_any_instance_of(Apis::Mapit::Client).to receive(:call).with("SE22 0HW").and_call_original

          expect(planning_application.ward).to eq("South Bermondsey")
          expect(planning_application.ward_type).to eq("London borough ward")
          expect(planning_application.parish_name).to eq("Southwark, unparished area")
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

    describe "::before_update #reset_validation_requests_update_counter" do
      let(:local_authority) { create :local_authority }
      let!(:planning_application) { create :planning_application, :invalidated, local_authority: local_authority }
      let(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, planning_application: planning_application) }
      let(:fee_item_validation_request) { create(:other_change_validation_request, :fee, :open, planning_application: planning_application, response: "a response") }

      context "when the red line boundary is made valid" do
        before { red_line_boundary_change_validation_request.close! }

        it "resets the update counter on the latest closed request" do
          expect(red_line_boundary_change_validation_request.update_counter?).to eq(true)

          planning_application.update!(valid_red_line_boundary: true)

          expect(red_line_boundary_change_validation_request.reload.update_counter?).to eq(false)
        end
      end

      context "when the fee item is made valid" do
        before { fee_item_validation_request.close! }

        it "resets the update counter on the latest closed request" do
          expect(fee_item_validation_request.update_counter?).to eq(true)

          planning_application.update!(valid_fee: true)

          expect(fee_item_validation_request.reload.update_counter?).to eq(false)
        end
      end
    end

    describe "::after_update" do
      context "when there is an update to any address or boundary geojson fields" do
        it "sets the updated_address_or_boundary_geojson to true" do
          planning_application.update!(address_1: "")

          expect(planning_application.updated_address_or_boundary_geojson).to eq(true)
        end
      end

      context "when there is an update but not to any address or boundary geojson fields" do
        it "does not set the updated_address_or_boundary_geojson to true" do
          planning_application.update!(agent_first_name: "Agent first name")

          expect(planning_application.updated_address_or_boundary_geojson).to eq(false)
        end
      end
    end
  end

  describe "constants" do
    describe "ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS" do
      it "returns address and boundary geojson fields as an array of symbols" do
        expect(PlanningApplication::ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS).to eq(
          %w[address_1 address_2 county postcode town uprn boundary_geojson]
        )
      end
    end
  end

  describe "#application_number" do
    before do
      planning_application.update(application_number: 130)
    end

    it "has a preceeding 0 before the application number" do
      expect(planning_application.application_number).to match(/^(?:0+130)$/)
    end

    it "has 5 characters length" do
      expect(planning_application.application_number).to match(/^\d{5}$/)
    end
  end

  describe "#reference_in_full" do
    let(:local_authority) { create(:local_authority, :southwark) }
    let(:planning_application1) { create(:planning_application, application_type: 0, local_authority: local_authority, work_status: "proposed") }
    let(:planning_application2) { create(:planning_application, application_type: 0, local_authority: local_authority, work_status: "existing") }

    before do
      travel_to Time.zone.local(2022, 10, 10)
    end

    it "returns a string constructed of the council code and reference for proposed LDCs" do
      expect(planning_application1.reference_in_full).to eq("SWK-22-00100-LDCP")
    end

    it "returns a string constructed of the council code and reference for existing LDCs" do
      expect(planning_application2.reference_in_full).to eq("SWK-22-00100-LDCE")
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
      context "when received_at is not set" do
        it "returns the correct business day for the application's created_at" do
          expect(planning_application.received_at).to eq Time.zone.local(2021, 9, 24, 9)
        end
      end

      context "when received_at is set" do
        before { planning_application.update!(received_at: date) }

        it "returns the received_at datetime" do
          expect(planning_application.received_at).to eq date
        end
      end
    end

    describe "#target_date" do
      context "when there were no documents validated" do
        before { planning_application.update!(validated_at: nil) }

        it "is set as received at + 35 days" do
          expect(planning_application.target_date).to eq(35.days.after(planning_application.received_at).to_date)
        end
      end

      context "when there are validated documents" do
        before { planning_application.update!(validated_at: 1.week.ago) }

        it "is set to validated_at + 35 days" do
          expect(planning_application.target_date).to eq(35.days.after(planning_application.validated_at).to_date)
        end
      end
    end

    describe "#expiry_date" do
      context "when there were no documents validated" do
        before { planning_application.update!(validated_at: nil) }

        it "is set as received_at + 56 days" do
          expect(planning_application.expiry_date).to eq(56.days.after(planning_application.received_at).to_date)
        end
      end

      context "when there are validated documents" do
        before { planning_application.update!(validated_at: 1.week.ago) }

        it "is set to validated_at + 56 days" do
          planning_application.update!(validated_at: 1.week.ago)
          expect(planning_application.expiry_date).to eq(56.days.after(planning_application.validated_at).to_date)
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
          travel_to(DateTime.new(2022, 8, 17))

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

  describe "#determination_date" do
    before { freeze_time }

    context "when there is no determination date set in the db" do
      it "returns today's date" do
        expect(planning_application.determination_date).to eq(Time.zone.today)
      end
    end

    context "when there is a determination date set in the db" do
      it "returns the determination date" do
        planning_application.update(determination_date: Time.current - 5.days)

        expect(planning_application.determination_date).to eq(Time.current - 5.days)
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
    let(:local_authority) do
      create(:local_authority, reviewer_group_email: "reviewers@example.com")
    end

    let(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        decision: "granted",
        local_authority: local_authority
      )
    end

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

      it "sends notification to reviewers" do
        expect { planning_application.submit_recommendation! }
          .to have_enqueued_job
          .on_queue("mailers")
          .with(
            "UserMailer",
            "update_notification_mail",
            "deliver_now",
            args: [planning_application, "reviewers@example.com"]
          )
      end
    end

    describe "when there is an error" do
      context "when it cannot transition from the current state" do
        before do
          planning_application.update(status: "awaiting_determination")
        end

        it "when planning application does not have status in_assessment it raises PlanningApplication::SubmitRecommendationError" do
          expect { planning_application.submit_recommendation! }
            .to raise_error(PlanningApplication::SubmitRecommendationError, "Event 'submit' cannot transition from 'awaiting_determination'.")
            .and change(Audit, :count).by(0)

          expect(planning_application).to be_awaiting_determination
        end
      end

      context "when there are open post validation requests" do
        before do
          create(:red_line_boundary_change_validation_request, :post_validation, planning_application: planning_application)
        end

        it "raises PlanningApplication::SubmitRecommendationError" do
          expect { planning_application.submit_recommendation! }
            .to raise_error(PlanningApplication::SubmitRecommendationError, "Event 'submit' cannot transition from 'in_assessment'. Failed callback(s): [:no_open_post_validation_requests?].")
            .and change(Audit, :count).by(0)

          expect(planning_application).to be_in_assessment
        end
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

  describe "#invalidation_response_due" do
    let(:planning_application) do
      create(:planning_application, invalidated_at: DateTime.new(2020, 6, 5))
    end

    it "returns date 15 business days after invalidated date" do
      expect(
        planning_application.invalidation_response_due
      ).to eq(
        Date.new(2020, 6, 26)
      )
    end
  end

  describe "#assign" do
    let(:planning_application) { create(:planning_application) }
    let(:user) { create(:user) }

    it "sends notification to assigned user" do
      expect { planning_application.assign(user) }
        .to have_enqueued_job
        .on_queue("mailers")
        .with(
          "UserMailer",
          "update_notification_mail",
          "deliver_now",
          args: [planning_application, user.email]
        )
    end
  end

  describe "#send_update_notification_to_assessor" do
    let(:user) { create(:user) }
    let(:planning_application) { create(:planning_application, user: user) }

    it "sends notification to assigned user" do
      expect { planning_application.send_update_notification_to_assessor }
        .to have_enqueued_job
        .on_queue("mailers")
        .with(
          "UserMailer",
          "update_notification_mail",
          "deliver_now",
          args: [planning_application, user.email]
        )
    end

    context "no user assigned" do
      let(:planning_application) { create(:planning_application, user: nil) }

      it "does not send notificationr" do
        expect do
          planning_application.send_update_notification_to_assessor
        end.not_to have_enqueued_job
      end
    end
  end

  describe "#send_update_notification_to_reviewers" do
    let(:local_authority) do
      create(:local_authority, reviewer_group_email: "reviewers@example.com")
    end

    let(:planning_application) do
      create(:planning_application, local_authority: local_authority)
    end

    it "sends notification to reviewer group email" do
      expect { planning_application.send_update_notification_to_reviewers }
        .to have_enqueued_job
        .on_queue("mailers")
        .with(
          "UserMailer",
          "update_notification_mail",
          "deliver_now",
          args: [planning_application, "reviewers@example.com"]
        )
    end

    context "no reviewer group email" do
      let(:local_authority) do
        create(:local_authority, reviewer_group_email: nil)
      end

      it "does not send notificationr" do
        expect do
          planning_application.send_update_notification_to_reviewers
        end.not_to have_enqueued_job
      end
    end
  end

  describe "#secure_change_url" do
    before do
      ENV["APPLICANTS_APP_HOST"] = "example.com"
    end

    it "returns the internal_url" do
      expect(planning_application.secure_change_url).to match("http://buckinghamshire.example.com/validation_requests")
    end

    context "when ENV['PUBLIC_URL_ENABLED'] is set to true" do
      before do
        ENV["PUBLIC_URL_ENABLED"] = "true"
        ENV["APPLICANTS_APP_HOST"] = "planning"
      end

      it "returns the public_url" do
        expect(planning_application.secure_change_url).to match("http://planning.buckinghamshire.gov.uk/validation_requests")
      end
    end
  end
end
