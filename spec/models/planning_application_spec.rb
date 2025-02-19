# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:planning_application) { create(:planning_application) }

  it_behaves_like("Auditable") do
    subject { create(:planning_application) }
  end

  describe "validations" do
    describe "#determination_date" do
      it "validates that date is not in the future" do
        planning_application = build(:planning_application, determination_date: 1.day.from_now)

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
        planning_application = build(:planning_application, determination_date: 1.day.ago)

        expect { planning_application.valid? }.not_to(change { planning_application.errors[:determination_date] })
      end
    end

    describe "#payment_amount" do
      it "validates that it must be greater than or equal to 0" do
        planning_application = build(:planning_application, payment_amount: "-1")

        expect { planning_application.valid? }.to change { planning_application.errors[:payment_amount] }
          .to ["Payment amount (£) must be greater than or equal to 0"]
      end

      it "validates that it must be less than maximum" do
        planning_application = build(:planning_application, payment_amount: "1000001")

        expect { planning_application.valid? }.to change { planning_application.errors[:payment_amount] }
          .to ["Payment amount (£) must be less than or equal to 1,000,000"]
      end

      [0, 12.43, "0", "1,200.00", "n"].each do |value|
        it "does not raise a validation error if value is #{value}" do
          planning_application = build(:planning_application, payment_amount: value)

          expect { planning_application.valid? }
            .not_to(change { planning_application.errors[:payment_amount] })
        end
      end
    end

    describe "#review_documents_for_recommendation_status" do
      it "validates the type of status" do
        planning_application = build(:planning_application, review_documents_for_recommendation_status: "bad_status")

        expect do
          planning_application.valid?
        end.to change {
          planning_application.errors[:review_documents_for_recommendation_status]
        }.to ["Review documents for recommendation status must be Not started, In progress or Complete"]
      end
    end

    describe "#user_is_non_administrator" do
      it "validates that a user assigned to the planning application is not an administrator" do
        planning_application = build(:planning_application, user: create(:user, :administrator))

        expect { planning_application.valid? }.to change { planning_application.errors[:user] }
          .to ["You cannot assign a planning application to an adminstrator"]
      end
    end
  end

  describe "associations" do
    describe "constraints" do
      let!(:planning_application) { create(:planning_application) }

      let!(:constraint1) { create(:constraint, type: "Constraint 1", category: "other") }
      let!(:constraint2) { create(:constraint, type: "Constraint 2", category: "other") }

      let!(:planning_application_constraints_query) { create(:planning_application_constraints_query, planning_application:) }
      let!(:planning_application_constraint1) { create(:planning_application_constraint, planning_application_constraints_query:, planning_application:, constraint: constraint1) }
      let!(:planning_application_constraint2) { create(:planning_application_constraint, planning_application_constraints_query:, planning_application:, constraint: constraint2) }

      it "returns the associations for constraints" do
        expect(constraint1.planning_application_constraints).to eq([planning_application_constraint1])
        expect(constraint2.planning_application_constraints).to eq([planning_application_constraint2])
      end

      it "returns the associations for planning_application_constraints_query" do
        expect(planning_application_constraints_query.constraints).to match_array([constraint1, constraint2])
        expect(planning_application_constraints_query.planning_application_constraints).to match_array([planning_application_constraint1, planning_application_constraint2])
        expect(planning_application_constraints_query.planning_application).to eq(planning_application)
      end

      it "returns the associations for planning_application" do
        expect(planning_application.planning_application_constraints).to match_array([planning_application_constraint1, planning_application_constraint2])
        # To change to "constraints" when we update the code to use the new association and are able to drop the "constraints" array field
        expect(planning_application.constraints).to match_array([constraint1, constraint2])
      end

      it "returns the associations for planning_application_constraint" do
        expect(planning_application_constraint1.planning_application).to eq(planning_application)
        expect(planning_application_constraint2.planning_application).to eq(planning_application)

        expect(planning_application_constraint1.planning_application_constraints_query).to eq(planning_application_constraints_query)
        expect(planning_application_constraint2.planning_application_constraints_query).to eq(planning_application_constraints_query)

        expect(planning_application_constraint1.constraint).to eq(constraint1)
        expect(planning_application_constraint2.constraint).to eq(constraint2)
      end
    end
  end

  describe "scopes" do
    describe ".by_created_at_desc" do
      let!(:planning_application1) { create(:planning_application, created_at: 1.day.ago) }
      let!(:planning_application2) { create(:planning_application, created_at: Time.zone.now) }
      let!(:planning_application3) { create(:planning_application, created_at: 2.days.ago) }

      it "returns planning applications sorted by created at desc (i.e. most recent first)" do
        expect(described_class.by_created_at_desc).to eq([planning_application2, planning_application1, planning_application3])
      end
    end

    describe ".by_latest_received_and_created" do
      before { freeze_time }

      let!(:planning_application1) { create(:planning_application, received_at: 2.days.ago, created_at: 3.days.ago) }
      let!(:planning_application2) { create(:planning_application, received_at: 2.days.ago, created_at: 4.days.ago) }
      let!(:planning_application3) { create(:planning_application, received_at: 1.day.ago, created_at: 1.day.ago) }

      it "returns planning applications sorted by latest received at and then created at" do
        expect(described_class.by_latest_received_and_created).to eq([planning_application3, planning_application1, planning_application2])
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
        let(:local_authority) { create(:local_authority) }
        let!(:planning_application) { create(:planning_application, local_authority:) }

        before do
          allow_any_instance_of(described_class).to receive(:set_application_number).and_return(planning_application.application_number)
        end

        it "raises a non unique error" do
          expect do
            create(:planning_application, local_authority:, application_number: 100)
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
        let(:local_authority) { create(:local_authority) }
        let(:planning_application1) { create(:planning_application, local_authority:) }
        let(:planning_application2) { create(:planning_application, local_authority:) }
        let(:planning_application3) { create(:planning_application, local_authority:) }
        let(:planning_application4) { create(:planning_application, local_authority:) }

        it "updates the application number incrementing after the existing maximum application number" do
          expect(planning_application1.application_number).to eq("00100")
          expect(planning_application2.application_number).to eq("00101")
          expect(planning_application3.application_number).to eq("00102")

          planning_application2.destroy

          expect(planning_application4.application_number).to eq("00103")
        end
      end

      context "when a planning application is discarded" do
        let(:local_authority) { create(:local_authority) }
        let(:planning_application1) { create(:planning_application, local_authority:) }
        let(:planning_application2) { create(:planning_application, local_authority:) }
        let(:planning_application3) { create(:planning_application, local_authority:) }
        let(:planning_application4) { create(:planning_application, local_authority:) }

        it "updates the application number incrementing after the existing maximum application number" do
          expect(planning_application1.application_number).to eq("00100")
          expect(planning_application2.application_number).to eq("00101")
          expect(planning_application3.application_number).to eq("00102")

          planning_application3.discard

          expect(planning_application4.application_number).to eq("00103")
        end
      end

      describe "#reference" do
        let(:planning_application) do
          build(:planning_application, :ldc_proposed)
        end

        it "is set when application is created" do
          travel_to(DateTime.new(2022, 1, 1)) do
            expect { planning_application.save }
              .to change(planning_application, :reference)
              .from(nil)
              .to("22-00100-LDCP")
          end
        end

        it "works for other planning application types" do
          planning_application = build(:planning_application, :prior_approval)

          travel_to(DateTime.new(2022, 1, 1)) do
            expect { planning_application.save }
              .to change(planning_application, :reference)
              .from(nil)
              .to("22-00100-PA1A")
          end
        end

        it "is set for the Householder Application for Planning Permission application type" do
          planning_application = build(:planning_application, :planning_permission)

          travel_to(DateTime.new(2022, 1, 1)) do
            expect { planning_application.save }
              .to change(planning_application, :reference)
              .from(nil)
              .to("22-00100-HAPP")
          end
        end
      end
    end

    describe "::after_create" do
      context "when there is a postcode set" do
        let(:planning_application) { create(:planning_application, postcode: "SE22 0HW") }

        it "calls the mapit API and sets the ward information" do
          expect_any_instance_of(Apis::Mapit::Client).to receive(:call).with("SE22 0HW").and_call_original

          expect(planning_application.ward).to eq("South Bermondsey")
          expect(planning_application.ward_type).to eq("London borough ward")
          expect(planning_application.parish_name).to eq("Southwark, unparished area")
        end
      end

      context "when there is no postcode set" do
        let(:planning_application) { create(:planning_application, postcode: nil) }

        it "does not call the mapit API" do
          expect_any_instance_of(Apis::Mapit::Client).not_to receive(:call)

          expect(planning_application.ward).to be_nil
          expect(planning_application.ward_type).to be_nil
        end
      end

      context "when a application type doesn't have a consultation" do
        let(:application_type) { create(:application_type) }
        let(:planning_application) { build(:planning_application, application_type:) }

        it "doesn't create a consultation record after creating the planning application" do
          expect { planning_application.save! }.not_to change(planning_application, :consultation).from(nil)
        end
      end

      context "when a application type has a consultation" do
        let(:application_type) { create(:application_type, :prior_approval) }
        let(:planning_application) { build(:planning_application, application_type:) }

        it "creates a consultation record after creating the planning application" do
          expect { planning_application.save! }.to change(planning_application, :consultation).from(nil).to(an_instance_of(Consultation))
        end
      end
    end

    describe "::before_update #reset_validation_requests_update_counter" do
      let(:local_authority) { create(:local_authority) }
      let!(:planning_application) { create(:planning_application, :invalidated, local_authority:) }
      let(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, planning_application:) }
      let(:fee_item_validation_request) { create(:fee_change_validation_request, :open, planning_application:, response: "a response") }

      context "when the red line boundary is made valid" do
        before { red_line_boundary_change_validation_request.close! }

        it "resets the update counter on the latest closed request" do
          expect(red_line_boundary_change_validation_request.update_counter?).to be(true)

          planning_application.update!(valid_red_line_boundary: true)

          expect(red_line_boundary_change_validation_request.reload.update_counter?).to be(false)
        end
      end

      context "when the fee item is made valid" do
        before { fee_item_validation_request.close! }

        it "resets the update counter on the latest closed request" do
          expect(fee_item_validation_request.update_counter?).to be(true)

          planning_application.update!(valid_fee: true)

          expect(fee_item_validation_request.reload.update_counter?).to be(false)
        end
      end
    end

    describe "::before_update" do
      context "when there is an update to any address or boundary geojson fields" do
        it "sets the updated_address_or_boundary_geojson to true" do
          planning_application.update!(address_1: "")

          expect(planning_application.updated_address_or_boundary_geojson).to be(true)
        end
      end

      context "when there is an update but not to any address or boundary geojson fields" do
        it "does not set the updated_address_or_boundary_geojson to true" do
          planning_application.update!(agent_first_name: "Agent first name")

          expect(planning_application.updated_address_or_boundary_geojson).to be(false)
        end
      end
    end

    describe "::before_update #audit_update_application_type" do
      let(:local_authority) { create(:local_authority, :southwark) }
      let(:assessor) { create(:user, :assessor, local_authority:) }
      let!(:pa_planning_application) do
        travel_to("2023-01-01") { create(:planning_application, :prior_approval, local_authority:) }
      end
      let!(:ldc_planning_application) do
        travel_to("2023-01-01") { create(:planning_application, :ldc_proposed, local_authority:) }
      end

      before { Current.user = assessor }

      context "when application type has not changed" do
        it "does not trigger the callback" do
          expect(Audit).not_to receive(:create!)
          ldc_planning_application.update!(description: "A description")

          expect(ldc_planning_application.reference).to eq("23-00101-LDCP")
        end
      end

      context "when application type has changed" do
        it "updates the application type id and sets a new application and reference number" do
          expect(pa_planning_application.reference).to eq("23-00100-PA1A")
          expect(ldc_planning_application.reference).to eq("23-00101-LDCP")

          travel_to("2023-02-01") do
            expect do
              ldc_planning_application.update!(application_type_id: ApplicationType.find_by(name: "prior_approval").id)
            end.to change(Audit, :count)
              .by(1)
              .and change(ldc_planning_application, :reference)
              .from("23-00101-LDCP").to("23-00101-PA1A")
              .and change(ldc_planning_application, :previous_references)
              .from([]).to(["23-00101-LDCP"])

            expect(Audit.last).to have_attributes(
              planning_application_id: ldc_planning_application.id,
              activity_type: "updated",
              activity_information: "Application type",
              audit_comment: "Application type changed from: Lawfulness certificate / Changed to: Prior approval,\n         Reference changed from 23-00101-LDCP to 23-00101-PA1A",
              user: assessor
            )
          end
        end
      end
    end

    describe "::after_update #update_constraints" do
      let(:boundary_geojson) do
        {
          type: "Feature",
          properties: {},
          geometry: {
            type: "Polygon",
            coordinates: [
              [
                [-0.054597, 51.537331],
                [-0.054588, 51.537287],
                [-0.054453, 51.537313],
                [-0.054597, 51.537331]
              ]
            ]
          }
        }.to_json
      end

      before do
        stub_planx_api_response_for("POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))").to_return(
          status: 200, body: "{}"
        )
      end

      context "when boundary_geojson is changed" do
        it "calls the ConstraintQueryUpdateJob" do
          expect do
            planning_application.update!(boundary_geojson:)
          end.to have_enqueued_job(ConstraintQueryUpdateJob).with(planning_application:)
        end
      end

      context "when boundary_geojson is not changed" do
        it "does not call the ConstraintQueryUpdateJob" do
          expect do
            planning_application.update!(address_1: "Address 1")
          end.not_to have_enqueued_job(ConstraintQueryUpdateJob)
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
    let(:planning_application1) { create(:planning_application, :ldc_proposed, local_authority:) }
    let(:planning_application2) { create(:planning_application, :ldc_existing, local_authority:) }

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

      expect(planning_application.reload.agent?).to be false
    end

    it "returns true if only name is given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last", agent_phone: "", agent_email: "")

      expect(planning_application.agent?).to be true
    end

    it "returns true if name and email are given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last",
        agent_phone: "", agent_email: "agent@example.com")

      expect(planning_application.agent?).to be true
    end

    it "returns true if name and phone are given" do
      planning_application.update!(agent_first_name: "first", agent_last_name: "last",
        agent_phone: "34433454", agent_email: "")

      expect(planning_application.agent?).to be true
    end
  end

  describe "#applicant?" do
    it "returns false if no values are given" do
      planning_application.update!(applicant_first_name: "", applicant_last_name: "",
        applicant_phone: "", applicant_email: "")

      expect(planning_application.applicant?).to be false
    end

    it "returns true if only name is given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
        applicant_phone: "", applicant_email: "")

      expect(planning_application.applicant?).to be true
    end

    it "returns true if name and email are given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
        applicant_phone: "", applicant_email: "applicant@example.com")

      expect(planning_application.applicant?).to be true
    end

    it "returns true if name and phone are given" do
      planning_application.update!(applicant_first_name: "first", applicant_last_name: "last",
        applicant_phone: "34433454", applicant_email: "")

      expect(planning_application.applicant?).to be true
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

        it "is set as received_at + DAYS_TO_EXPIRE days" do
          expect(planning_application.expiry_date)
            .to eq(PlanningApplication::DAYS_TO_EXPIRE.days.after(planning_application.received_at).to_date)
        end
      end

      context "when there are validated documents" do
        before { planning_application.update!(validated_at: 1.week.ago) }

        it "is set to validated_at + DAYS_TO_EXPIRE days" do
          expect(planning_application.expiry_date)
            .to eq(PlanningApplication::DAYS_TO_EXPIRE.days.after(planning_application.validated_at).to_date)
        end
      end

      context "when application type has set the determination period days" do
        let(:application_type) { create(:application_type, :planning_permission, determination_period_days: 20) }
        let(:planning_application) { create(:planning_application, :not_started, application_type:) }

        it "is set to received_at + application type determination period days" do
          expect(planning_application.expiry_date).to eq(20.days.after(planning_application.received_at).to_date)
        end

        context "when planning application has been validated" do
          before { planning_application.update!(validated_at: 5.days.from_now) }

          it "is set to validated_at + application type determination period days" do
            expect(planning_application.expiry_date).not_to eq(20.days.after(planning_application.received_at).to_date)
            expect(planning_application.expiry_date).to eq(20.days.after(planning_application.validated_at).to_date)
          end
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
      let(:planning_application) { create(:valid_planning_application) }

      it "is validated at" do
        expect(planning_application.valid_from).to eq(planning_application.validated_at)
      end
    end
  end

  describe "#valid_from_date" do
    let(:planning_application) { create(:not_started_planning_application) }

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
              planning_application:,
              updated_at: at
            )
          end

          planning_application.start!
        end

        it "is the time of the last successfully closed request" do
          expect(planning_application.valid_from_date).to eq Time.next_immediate_business_day(1.day.ago)
        end
      end

      context "when there have been no validation requests" do
        before { planning_application.start! }

        it "returns the received_at value" do
          expect(planning_application.valid_from_date).to eq planning_application.received_at
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
        planning_application.update(determination_date: 5.days.ago)

        expect(planning_application.determination_date).to eq(5.days.ago)
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
    context "when column value is nil" do
      let(:planning_application) do
        build(:planning_application, proposal_details: nil)
      end

      it "returns empty array" do
        expect(planning_application.proposal_details).to eq([])
      end
    end

    context "when column value is present" do
      let(:proposal_details) do
        [
          {
            question: "Test question?",
            responses: [{value: "Test response"}],
            metadata: {
              auto_answered: true,
              portal_name: "Test portal",
              policy_refs: [
                {
                  text: "Test ref text",
                  url: "https://www.exampleref.com"
                }
              ],
              notes: "Test notes",
              flags: ["Test flag"]
            }
          }
        ]
      end

      let(:planning_application) do
        build(:planning_application, proposal_details:)
      end

      it "returns array of ProposalDetail instances" do
        expect(
          planning_application.proposal_details.first
        ).to be_instance_of(
          ProposalDetail
        )
      end
    end
  end

  describe "flagged_proposal_details" do
    it "returns the relevant questions for the application's result" do
      expect(
        planning_application.flagged_proposal_details.length
      ).to eq 1
    end

    context "when there's a proposal detail with multiple responses" do
      before do
        planning_application.proposal_details = JSON.parse(File.read("./spec/fixtures/files/multiple_responses_proposal_details.json"))
      end

      it "does not crash" do
        expect do
          planning_application.flagged_proposal_details
        end.not_to raise_error
      end
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  describe "immune_proposal_details" do
    let(:proposal_details) do
      [
        {
          question: "Test question?",
          responses: [
            {
              value: "Test response",
              metadata: {
                flags: ["Planning permission / Immune"]
              }
            }
          ],
          metadata: {
            auto_answered: true,
            portal_name: "immunity-check",
            policy_refs: [
              {
                text: "Test ref text",
                url: "https://www.exampleref.com"
              }
            ],
            notes: "Test notes",
            flags: ["Test flag"]
          }
        }
      ]
    end

    let(:planning_application) do
      build(:planning_application, proposal_details:)
    end

    it "returns the relevant questions for the application's result" do
      expect(
        planning_application.immune_proposal_details.length
      ).to eq 1
    end

    context "when there's a proposal detail with multiple responses" do
      before do
        planning_application.proposal_details = JSON.parse(File.read("./spec/fixtures/files/multiple_responses_proposal_details.json"))
      end

      it "does not crash" do
        expect do
          planning_application.immune_proposal_details
        end.not_to raise_error
      end
    end
  end

  describe "find_proposal_detail" do
    let(:proposal_details) do
      [
        {
          question: "Test question?",
          responses: [{value: "Test response"}],
          metadata: {
            auto_answered: true,
            portal_name: "immunity-check"
          }
        },
        {
          question: "Test question 2?",
          responses: [{value: "Test response"}],
          metadata: {
            auto_answered: true,
            portal_name: "immunity-check"
          }
        }
      ]
    end

    let(:planning_application) do
      build(:planning_application, proposal_details:)
    end

    it "returns the question from the proposal details" do
      expect(
        planning_application.find_proposal_detail("Test question?").length
      ).to eq 1

      expect(planning_application.find_proposal_detail("Test question?").first.question).to eq "Test question?"
    end

    it "does not crash" do
      expect do
        planning_application.find_proposal_detail("Test question that doesn't exist?")
      end.not_to raise_error
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
        local_authority:
      )
    end

    let(:recommendation) { create(:recommendation, planning_application:, submitted: "false") }
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
          .and change(planning_application.recommendation.reload, :submitted).from(false).to(true)

        expect(planning_application.awaiting_determination_at).to eq(Time.current)

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "submitted",
          user:
        )
      end

      it "sends notification to reviewers" do
        expect { planning_application.submit_recommendation! }
          .to have_enqueued_job
          .on_queue("low_priority")
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
            .and not_change(Audit, :count)

          expect(planning_application).to be_awaiting_determination
        end
      end

      context "when there are open post validation requests" do
        before do
          create(:red_line_boundary_change_validation_request, :post_validation, planning_application:)
          create(:committee_decision, planning_application:)
        end

        it "raises PlanningApplication::SubmitRecommendationError" do
          expect { planning_application.submit_recommendation! }
            .to raise_error(PlanningApplication::SubmitRecommendationError, "Event 'submit' cannot transition from 'in_assessment'. Failed callback(s): [:no_open_post_validation_requests_excluding_time_extension?].")
            .and not_change(Audit, :count)

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
          .and change(planning_application.recommendation.reload, :submitted).from(true).to(false)

        expect(planning_application.in_assessment_at).to eq(Time.current)

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "withdrawn_recommendation",
          user:
        )
      end
    end

    describe "when there is an error" do
      it "when planning application is not in awaiting_determination it raises PlanningApplication::WithdrawRecommendationError" do
        planning_application.update(status: "determined")

        expect { planning_application.withdraw_last_recommendation! }
          .to raise_error(PlanningApplication::WithdrawRecommendationError, "Event 'withdraw_recommendation' cannot transition from 'determined'.")
          .and not_change(Audit, :count)

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

  describe "#closed_pre_validation_requests" do
    let(:planning_application) { create(:planning_application, :not_started) }
    let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :closed, planning_application:) }
    let!(:other_change_validation_request) { create(:other_change_validation_request, :pending, planning_application:) }

    before do
      planning_application.validate!
    end

    it "returns closed validation requests made in validation, rather than assessment" do
      create(:description_change_validation_request, :closed, post_validation: true, planning_application:)

      expect(planning_application.closed_pre_validation_requests).to contain_exactly(red_line_boundary_change_validation_request)
    end
  end

  describe "#overdue_validation_requests" do
    let(:planning_application) { create(:planning_application, :invalidated) }
    let!(:not_overdue_validation_request1) { create(:red_line_boundary_change_validation_request, :open, created_at: Time.zone.now, planning_application:) }
    let!(:not_overdue_validation_request2) { create(:other_change_validation_request, :pending, created_at: Time.zone.now, planning_application:) }
    let!(:not_overdue_validationrequest3) { create(:fee_change_validation_request, :pending, created_at: 20.days.ago, planning_application:) }
    let!(:overdue_validation_request) { create(:description_change_validation_request, :open, created_at: 20.days.ago, planning_application:) }

    it "returns overdue validation requests" do
      expect(planning_application.overdue_validation_requests).to contain_exactly(overdue_validation_request)
    end
  end

  describe "#assign!" do
    let(:planning_application) { create(:planning_application) }
    let(:user) { create(:user) }

    context "when an LDC application" do
      it "sends notification to assigned user" do
        expect { planning_application.assign!(user) }
          .to have_enqueued_job
          .on_queue("low_priority")
          .with(
            "UserMailer",
            "update_notification_mail",
            "deliver_now",
            args: [planning_application, user.email]
          )
      end
    end

    context "when a prior approval application" do
      before do
        prior_approval = create(:application_type, :prior_approval)
        planning_application.update(application_type: prior_approval)
      end

      it "sends notification to assigned user" do
        expect { planning_application.assign!(user) }
          .to have_enqueued_job
          .on_queue("low_priority")
          .with(
            "UserMailer",
            "assigned_notification_mail",
            "deliver_now",
            args: [planning_application, user.email]
          )
      end
    end

    context "when an ActiveRecord error is raised" do
      before do
        allow(planning_application).to receive(:update!).and_raise(ActiveRecord::ActiveRecordError)
      end

      it "raises an error and does not create an audit" do
        expect { planning_application.assign!(user) }
          .to raise_error(ActiveRecord::ActiveRecordError)
          .and not_change(planning_application, :user_id)
          .and not_change(Audit, :count)
      end
    end
  end

  describe "#send_update_notification_to_assessor" do
    let(:user) { create(:user) }
    let(:planning_application) { create(:planning_application, user:) }

    it "sends notification to assigned user" do
      expect { planning_application.send_update_notification_to_assessor }
        .to have_enqueued_job
        .on_queue("low_priority")
        .with(
          "UserMailer",
          "update_notification_mail",
          "deliver_now",
          args: [planning_application, user.email]
        )
    end

    context "with no user assigned" do
      let(:planning_application) { create(:planning_application, user: nil) }

      it "does not send notification" do
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
      create(:planning_application, local_authority:)
    end

    it "sends notification to reviewer group email" do
      expect { planning_application.send_update_notification_to_reviewers }
        .to have_enqueued_job
        .on_queue("low_priority")
        .with(
          "UserMailer",
          "update_notification_mail",
          "deliver_now",
          args: [planning_application, "reviewers@example.com"]
        )
    end

    context "with no reviewer group email" do
      let(:local_authority) do
        create(:local_authority, reviewer_group_email: nil)
      end

      it "does not send notification" do
        expect do
          planning_application.send_update_notification_to_reviewers
        end.not_to have_enqueued_job
      end
    end
  end

  describe "#secure_change_url" do
    let(:local_authority) { planning_application.local_authority }

    it "returns the applicants url from the local authority" do
      expect(local_authority).to receive(:applicants_url).and_return("https://planning.buckinghamshire.gov.uk")
      expect(planning_application.secure_change_url).to match(%r{https://planning\.buckinghamshire\.gov\.uk/validation_requests})
    end
  end

  describe "#assessment_submitted?" do
    context "when planning application is to be reviewed" do
      let(:planning_application) do
        create(:planning_application, :to_be_reviewed)
      end

      it "returns true" do
        expect(planning_application.assessment_submitted?).to be(true)
      end
    end

    context "when planning application is awaiting determination" do
      let(:planning_application) do
        create(:planning_application, :awaiting_determination)
      end

      it "returns true" do
        expect(planning_application.assessment_submitted?).to be(true)
      end
    end

    context "when planning application is determined" do
      let(:planning_application) { create(:planning_application, :determined) }

      it "returns true" do
        expect(planning_application.assessment_submitted?).to be(true)
      end
    end

    context "when planning application is in assessment" do
      let(:planning_application) do
        create(:planning_application, :in_assessment)
      end

      it "returns false" do
        expect(planning_application.assessment_submitted?).to be(false)
      end
    end

    context "when recommendation is pending review" do
      let(:planning_application) do
        create(:planning_application, :in_assessment)
      end

      let!(:recommendation) do
        create(
          :recommendation,
          planning_application:,
          reviewer: nil
        )
      end

      it "returns true" do
        expect(planning_application.assessment_submitted?).to be(true)
      end

      context "when planning application is not started" do
        let(:planning_application) do
          create(:planning_application, :not_started)
        end

        it "returns false" do
          expect(planning_application.assessment_submitted?).to be(false)
        end
      end

      context "when planning application state is 'assessment in progress'" do
        let(:planning_application) do
          create(:planning_application, :assessment_in_progress)
        end

        it "returns false" do
          expect(planning_application.assessment_submitted?).to be(false)
        end
      end
    end
  end

  describe "#existing_or_new_recommendation" do
    let(:planning_application) { create(:planning_application) }

    context "when planning application has no recommendation" do
      it "returns new recommendation" do
        expect(
          planning_application.existing_or_new_recommendation
        ).to have_attributes(
          planning_application_id: planning_application.id,
          id: nil
        )
      end
    end

    context "when planning application has existing recommendation" do
      let!(:recommendation) do
        create(:recommendation, planning_application:)
      end

      it "returns new recommendation" do
        expect(
          planning_application.existing_or_new_recommendation
        ).to eq(
          recommendation
        )
      end
    end
  end

  describe "#recommendation_assessment_in_progress?" do
    let(:planning_application) { create(:planning_application) }

    let!(:recommendation) do
      create(
        :recommendation,
        planning_application:,
        status:
      )
    end

    context "when recommendation has status of 'assessment_in_progress'" do
      let(:status) { :assessment_in_progress }

      it "returns true" do
        expect(
          planning_application.recommendation_assessment_in_progress?
        ).to be(
          true
        )
      end
    end

    context "when recommendation does not have status of 'assessment_in_progress'" do
      let(:status) { :assessment_complete }

      it "returns false" do
        expect(
          planning_application.recommendation_assessment_in_progress?
        ).to be(
          false
        )
      end
    end
  end

  describe "#recommendation_assessment_complete?" do
    let(:planning_application) { create(:planning_application) }

    let!(:recommendation) do
      create(
        :recommendation,
        planning_application:,
        status:
      )
    end

    context "when recommendation has status of 'assessment_complete'" do
      let(:status) { :assessment_complete }

      it "returns true" do
        expect(
          planning_application.recommendation_assessment_complete?
        ).to be(
          true
        )
      end
    end

    context "when recommendation does not have status of 'assessment_complete'" do
      let(:status) { :assessment_in_progress }

      it "returns false" do
        expect(
          planning_application.recommendation_assessment_complete?
        ).to be(
          false
        )
      end
    end
  end

  describe "#recommendation_review_in_progress?" do
    let(:planning_application) { create(:planning_application) }

    let!(:recommendation) do
      create(
        :recommendation,
        planning_application:,
        status:
      )
    end

    context "when recommendation has status of 'review_in_progress'" do
      let(:status) { :review_in_progress }

      it "returns true" do
        expect(
          planning_application.recommendation_review_in_progress?
        ).to be(
          true
        )
      end
    end

    context "when recommendation does not have status of 'review_in_progress'" do
      let(:status) { :assessment_complete }

      it "returns false" do
        expect(
          planning_application.recommendation_review_in_progress?
        ).to be(
          false
        )
      end
    end
  end

  describe "#recommendation_review_complete?" do
    let(:planning_application) { create(:planning_application) }

    let!(:recommendation) do
      create(
        :recommendation,
        planning_application:,
        status:
      )
    end

    context "when recommendation has status of 'review_complete'" do
      let(:status) { :review_complete }

      it "returns true" do
        expect(
          planning_application.recommendation_review_complete?
        ).to be(
          true
        )
      end
    end

    context "when recommendation does not have status of 'review_complete'" do
      let(:status) { :assessment_complete }

      it "returns false" do
        expect(
          planning_application.recommendation_review_complete?
        ).to be(
          false
        )
      end
    end
  end

  describe "#last_recommendation_accepted?" do
    let(:local_authority) do
      create(:local_authority, reviewer_group_email: "reviewers@example.com")
    end

    let(:planning_application) do
      create(
        :planning_application,
        :review_in_progress,
        :in_assessment,
        local_authority:
      )
    end

    context "when challenged or challenge unasked" do
      statuses = %i[assessment_in_progress assessment_complete review_in_progress review_complete]
      %i[true nil].each do |challenge|
        statuses.each do |status|
          it "returns false when #{status} and the last recommendation when challenge is #{challenge}" do
            create(:recommendation,
              status:,
              challenged: challenge,
              reviewer_comment: "Nope",
              planning_application:)

            expect(planning_application.last_recommendation_accepted?).to be false
          end
        end
      end
    end

    context "when unchallenged" do
      %i[assessment_in_progress assessment_complete review_in_progress].each do |status|
        it "returns false when #{status} and the last recommendation is challenged" do
          create(:recommendation,
            status:,
            challenged: false,
            planning_application:)

          expect(planning_application.last_recommendation_accepted?).to be false
        end
      end

      it "returns true when the last recommendation is accepted" do
        create(:recommendation,
          status: :review_complete,
          challenged: false,
          planning_application:)

        expect(planning_application.last_recommendation_accepted?).to be true
      end
    end
  end

  describe "#rejected_assessment_detail" do
    let(:planning_application) { create(:planning_application) }
    let(:review_status) { :complete }
    let(:reviewer_verdict) { :rejected }

    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        review_status:,
        reviewer_verdict:
      )
    end

    context "when assessment detail is rejected" do
      it "returns assessment_detail" do
        expect(
          planning_application.rejected_assessment_detail(
            category: :summary_of_work
          )
        ).to eq(assessment_detail)
      end
    end

    context "when assessment_detail accepted" do
      let(:reviewer_verdict) { :accepted }

      it "returns nil" do
        expect(
          planning_application.rejected_assessment_detail(
            category: :summary_of_work
          )
        ).to be_nil
      end
    end

    context "when assessment_detail review not complete" do
      let(:review_status) { :in_progress }

      it "returns nil" do
        expect(
          planning_application.rejected_assessment_detail(
            category: :summary_of_work
          )
        ).to be_nil
      end
    end
  end

  describe "#existing_or_new_summary_of_work" do
    let(:planning_application) { create(:planning_application) }

    context "when record exists" do
      let!(:assessment_detail) do
        create(
          :assessment_detail,
          :summary_of_work,
          planning_application:
        )
      end

      it "returns record" do
        expect(
          planning_application.existing_or_new_summary_of_work
        ).to eq(assessment_detail)
      end
    end

    context "when record does not exist" do
      it "builds record with correct category" do
        expect(
          planning_application.existing_or_new_summary_of_work
        ).to have_attributes(category: "summary_of_work")
      end
    end
  end

  describe "#existing_or_new_additional_evidence" do
    let(:planning_application) { create(:planning_application) }

    context "when record exists" do
      let!(:assessment_detail) do
        create(
          :assessment_detail,
          :additional_evidence,
          planning_application:
        )
      end

      it "returns record" do
        expect(
          planning_application.existing_or_new_additional_evidence
        ).to eq(assessment_detail)
      end
    end

    context "when record does not exist" do
      it "builds record with correct category" do
        expect(
          planning_application.existing_or_new_additional_evidence
        ).to have_attributes(category: "additional_evidence")
      end
    end
  end

  describe "#existing_or_new_consultation_summary" do
    let(:planning_application) { create(:planning_application) }
    let(:consultation) { create(:consultation, planning_application:) }

    before { create(:consultee, consultation:) }

    context "when record exists" do
      let!(:assessment_detail) do
        create(
          :assessment_detail,
          :consultation_summary,
          planning_application:
        )
      end

      it "returns record" do
        expect(
          planning_application.existing_or_new_consultation_summary
        ).to eq(assessment_detail)
      end
    end

    context "when record does not exist" do
      it "builds record with correct category" do
        expect(
          planning_application.existing_or_new_consultation_summary
        ).to have_attributes(category: "consultation_summary")
      end
    end
  end

  describe "#existing_or_new_site_description" do
    let(:planning_application) { create(:planning_application) }

    context "when record exists" do
      let!(:assessment_detail) do
        create(
          :assessment_detail,
          :site_description,
          planning_application:
        )
      end

      it "returns record" do
        expect(
          planning_application.existing_or_new_site_description
        ).to eq(assessment_detail)
      end
    end

    context "when record does not exist" do
      it "builds record with correct category" do
        expect(
          planning_application.existing_or_new_site_description
        ).to have_attributes(category: "site_description")
      end
    end
  end

  describe "#summary_of_work" do
    let(:planning_application) { create(:planning_application) }

    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns most recente assessment detail with category 'summary_of_work'" do
      expect(planning_application.summary_of_work).to eq(assessment_detail)
    end
  end

  describe "#additional_evidence" do
    let(:planning_application) { create(:planning_application) }

    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :additional_evidence,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :assessment_detail,
        :additional_evidence,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns most recent assessment detail with category 'additional_evidence'" do
      expect(planning_application.additional_evidence).to eq(assessment_detail)
    end
  end

  describe "#site_description" do
    let(:planning_application) { create(:planning_application) }

    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :site_description,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :assessment_detail,
        :site_description,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns most recent assessment detail with category 'site_description'" do
      expect(planning_application.site_description).to eq(assessment_detail)
    end
  end

  describe "#consultation_summary" do
    let(:planning_application) do
      create(:planning_application, :with_consultees)
    end

    let!(:assessment_detail1) do
      create(
        :assessment_detail,
        :consultation_summary,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    let!(:assessment_detail2) do
      create(
        :assessment_detail,
        :consultation_summary,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns most recent assessment detail with category 'consultation_summary'" do
      expect(planning_application.consultation_summary).to eq(assessment_detail1)
    end
  end

  describe "#red_line_boundary_change_validation_request" do
    let(:planning_application) { create(:planning_application) }

    let!(:request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns latest request" do
      expect(
        planning_application.red_line_boundary_change_validation_request
      ).to eq(
        request
      )
    end
  end

  describe "#additional_document_validation_request" do
    let(:planning_application) { create(:planning_application) }

    let!(:request) do
      create(
        :additional_document_validation_request,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :additional_document_validation_request,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns latest request" do
      expect(
        planning_application.additional_document_validation_request
      ).to eq(
        request
      )
    end
  end

  describe "#description_change_validation_request" do
    let(:planning_application) { create(:planning_application) }

    let!(:request) do
      create(
        :description_change_validation_request,
        :closed,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :description_change_validation_request,
        :closed,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns latest request" do
      expect(
        planning_application.description_change_validation_request
      ).to eq(
        request
      )
    end
  end

  describe "#replacement_document_validation_request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:request) do
      create(
        :replacement_document_validation_request,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :replacement_document_validation_request,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns latest request" do
      expect(
        planning_application.replacement_document_validation_request
      ).to eq(
        request
      )
    end
  end

  describe "#other_change_validation_request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:request) do
      create(
        :other_change_validation_request,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :other_change_validation_request,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns latest request" do
      expect(
        planning_application.other_change_validation_request
      ).to eq(
        request
      )
    end
  end

  describe "#assessment_details_for_review" do
    let(:planning_application) do
      create(:planning_application, :with_consultees)
    end

    let!(:summary_of_work) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    let!(:consultation_summary) do
      create(
        :assessment_detail,
        :consultation_summary,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    let!(:site_description) do
      create(
        :assessment_detail,
        :site_description,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    let!(:additional_evidence) do
      create(
        :assessment_detail,
        :additional_evidence,
        planning_application:,
        created_at: 1.day.ago
      )
    end

    before do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        created_at: 2.days.ago
      )

      create(
        :assessment_detail,
        :consultation_summary,
        planning_application:,
        created_at: 2.days.ago
      )

      create(
        :assessment_detail,
        :site_description,
        planning_application:,
        created_at: 2.days.ago
      )

      create(
        :assessment_detail,
        :additional_evidence,
        planning_application:,
        created_at: 2.days.ago
      )
    end

    it "returns most recent assessment detail in each reviewable category" do
      expect(planning_application.assessment_details_for_review).to contain_exactly(
        summary_of_work, additional_evidence, site_description, consultation_summary
      )
    end
  end

  describe "#updates_required?" do
    let(:planning_application) { create(:planning_application) }

    context "when no changes requested" do
      it "returns nil" do
        expect(planning_application.updates_required?).to be(nil)
      end
    end

    context "when changes to permitted development right requested" do
      before do
        create(
          :permitted_development_right,
          review_status: :review_complete,
          accepted: false,
          planning_application:
        )
      end

      it "returns true" do
        expect(planning_application.updates_required?).to be(true)
      end
    end

    context "when changes to assessment_detail requested" do
      before do
        create(
          :assessment_detail,
          planning_application:,
          review_status: :complete,
          reviewer_verdict: :rejected
        )
      end

      it "returns true" do
        expect(planning_application.updates_required?).to be(true)
      end
    end

    context "when changes committee decision requested" do
      before do
        committee_decision = create(
          :committee_decision,
          planning_application:
        )
        committee_decision.current_review.update(action: "rejected", comment: "no")
      end

      it "returns true" do
        expect(planning_application.updates_required?).to be(true)
      end
    end

    context "when changes to the neighbour responses requested" do
      before do
        consultation = create(:consultation, planning_application:)
        create(:review, owner: consultation, status: "to_be_reviewed")
      end

      it "returns true" do
        expect(planning_application.updates_required?).to be(true)
      end
    end
  end

  describe "#review_in_progress?" do
    let(:planning_application) { create(:planning_application) }

    let!(:recommendation) do
      create(
        :recommendation,
        planning_application:,
        status: recommendation_status
      )
    end

    let(:recommendation_status) { :assessment_complete }

    context "when recommendation review is in progress" do
      let(:recommendation_status) { :review_in_progress }

      it "returns true" do
        expect(planning_application.review_in_progress?).to be(true)
      end
    end

    context "when assessment details review is in progress" do
      before do
        create(
          :assessment_detail,
          planning_application:,
          reviewer_verdict: :accepted
        )
      end

      it "returns true" do
        expect(planning_application.review_in_progress?).to be(true)
      end
    end

    context "when permitted development right review is in progress" do
      before do
        create(
          :permitted_development_right,
          planning_application:,
          review_status: :review_in_progress
        )
      end

      it "returns true" do
        expect(planning_application.review_in_progress?).to be(true)
      end
    end
  end

  describe "#withdraw_or_cancel!" do
    let(:local_authority) { create(:local_authority, reviewer_group_email: "reviewers@example.com") }

    let(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        local_authority:
      )
    end

    describe "when successful" do
      context "when withdrawn by applicant" do
        it "application is withdrawn" do
          expect { planning_application.withdraw_or_cancel!("withdrawn", "a withdrawn comment", nil) }
            .to change(planning_application, :status).from("in_assessment").to("withdrawn")

          expect(planning_application.closed_or_cancellation_comment).to eq("a withdrawn comment")
          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "withdrawn",
            audit_comment: "a withdrawn comment"
          )
        end
      end

      context "when returned as invalid" do
        it "application is returned" do
          expect { planning_application.withdraw_or_cancel!("returned", "a returned comment", nil) }
            .to change(planning_application, :status).from("in_assessment").to("returned")

          expect(planning_application.closed_or_cancellation_comment).to eq("a returned comment")
          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "returned",
            audit_comment: "a returned comment"
          )
        end
      end

      context "when closed for other reason" do
        it "application is closed" do
          expect { planning_application.withdraw_or_cancel!("closed", "a closed comment", nil) }
            .to change(planning_application, :status).from("in_assessment").to("closed")

          expect(planning_application.closed_or_cancellation_comment).to eq("a closed comment")
          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "closed",
            audit_comment: "a closed comment"
          )
        end
      end
    end

    describe "when there is an error" do
      context "when it cannot transition from the current state" do
        let!(:planning_application) do
          create(
            :planning_application,
            :closed,
            local_authority:
          )
        end

        it "raises an error" do
          expect { planning_application.withdraw_or_cancel!("closed", "a closed comment", nil) }
            .to raise_error(PlanningApplication::WithdrawOrCancelError, "Event 'close' cannot transition from 'closed'.")
            .and not_change(planning_application, :closed_or_cancellation_comment)
            .and not_change(Audit, :count)

          expect(planning_application).to be_closed
        end
      end

      context "when an invalid status is provided" do
        it "raises an error" do
          expect { planning_application.withdraw_or_cancel!("invalid_state", "A comment", nil) }
            .to raise_error(ArgumentError, "The status provided: invalid_state is not valid")
            .and not_change(planning_application, :closed_or_cancellation_comment)
            .and not_change(Audit, :count)
        end
      end

      context "when an ActiveRecord error is raised" do
        before do
          allow(planning_application).to receive(:update!).and_raise(ActiveRecord::ActiveRecordError)
        end

        it "raises an error" do
          expect { planning_application.withdraw_or_cancel!("closed", "A comment", nil) }
            .to raise_error(PlanningApplication::WithdrawOrCancelError)
            .and not_change(planning_application, :closed_or_cancellation_comment)
            .and not_change(Audit, :count)

          expect(planning_application).not_to be_closed
        end
      end
    end
  end

  describe "#mark_legislation_as_checked!" do
    let(:planning_application) { create(:planning_application) }

    it "sets legislation_checked as true and adds an audit record" do
      expect { planning_application.mark_legislation_as_checked! }
        .to change(planning_application, :legislation_checked)
        .from(false)
        .to(true)

      expect(Audit.last).to have_attributes(
        planning_application_id: planning_application.id,
        activity_type: "legislation_checked"
      )
    end
  end

  describe "#generate_document_tabs" do
    let!(:document_no_tag) { create(:document, tags: [], planning_application:) }
    let!(:document_evidence_tag) { create(:document, tags: %w[photographs.existing], planning_application:) }
    let!(:document_plan_tag) { create(:document, tags: %w[floorPlan.proposed], planning_application:) }
    let!(:document_supporting_tag) { create(:document, tags: %w[noiseAssessment], planning_application:) }
    let!(:document_evidence_and_plan_tags) { create(:document, tags: %w[photographs.proposed floorPlan.proposed], planning_application:) }
    let!(:document_plan_and_supporting_tags) { create(:document, tags: %w[floorPlan.proposed otherDocument], planning_application:) }
    let!(:document_archived) { create(:document, :archived, tags: [], planning_application:) }

    def find_tab(title)
      planning_application.generate_document_tabs.find { |tab| tab[:title] == title }
    end

    it "returns all documents for the 'All' tab" do
      all_tab = find_tab("All")

      expect(all_tab).to eq({
        title: "All",
        id: "all",
        content: "All",
        records: [document_no_tag, document_evidence_tag, document_plan_tag, document_supporting_tag, document_evidence_and_plan_tags, document_plan_and_supporting_tags]
      })
    end

    it "filters documents for the 'Evidence' tab" do
      evidence_tab = find_tab("Evidence")

      expect(evidence_tab).to eq({
        title: "Evidence",
        id: "evidence",
        content: "Evidence",
        records: [document_evidence_tag, document_evidence_and_plan_tags]
      })
    end

    it "filters documents for the 'Drawings' tab" do
      plans_tab = find_tab("Drawings")

      expect(plans_tab).to eq({
        title: "Drawings",
        id: "drawings",
        content: "Drawings",
        records: [document_plan_tag, document_evidence_and_plan_tags, document_plan_and_supporting_tags]
      })
    end

    it "filters documents for the 'Supporting documents' tab" do
      supporting_documents_tab = find_tab("Supporting documents")

      expect(supporting_documents_tab).to eq({
        title: "Supporting documents",
        id: "supporting-documents",
        content: "Supporting documents",
        records: [document_supporting_tag, document_plan_and_supporting_tags]
      })
    end

    it "filters out archived documents" do
      all_tab = find_tab("All")

      expect(all_tab[:records]).not_to include(document_archived)
    end
  end

  describe "#neighbour_geojson" do
    let(:feature_collection) do
      {
        type: "FeatureCollection",
        features: [
          {
            "type" => "Feature",
            "properties" => {},
            "geometry" => {
              "type" => "Polygon",
              "coordinates" => [
                [[10, 10], [30, 30], [20, 20], [20, 10], [20, 30]]
              ]
            }
          }
        ]
      }
    end

    context "when the neighbour boundary geojson is present" do
      before do
        factory = RGeo::Geographic.spherical_factory(srid: 4326)
        point = factory.point(-0.01, 51.0)
        geometry_collection = factory.collection([point])

        planning_application.update(neighbour_boundary_geojson: geometry_collection)
      end

      it "returns the geojson" do
        expect(planning_application.neighbour_geojson).to eq(
          {
            "type" => "FeatureCollection",
            "features" => [
              {
                "geometry" => {
                  "coordinates" => [
                    -0.01,
                    51.0
                  ],
                  "type" => "Point"
                },
                "type" => "Feature"
              }
            ]
          }
        )
      end

      it "returns the geojson with drawn polygon if it's been drawn" do
        create(:consultation, planning_application:, polygon_geojson: feature_collection.to_json)

        expect(planning_application.reload.neighbour_geojson).to eq(
          {
            "type" => "FeatureCollection",
            "features" => [
              {
                "geometry" => {
                  "coordinates" => [
                    -0.01,
                    51.0
                  ],
                  "type" => "Point"
                },
                "type" => "Feature"
              },
              {
                "type" => "Feature",
                "properties" => {
                  color: "#d870fc"
                },
                "geometry" => {
                  "coordinates" => [[[10.0, 10.0], [30.0, 30.0], [20.0, 20.0], [20.0, 10.0], [20.0, 30.0], [10.0, 10.0]]],
                  "type" => "Polygon"
                }
              }
            ]
          }
        )
      end
    end

    context "when the neighbour boundary geojson isn't present" do
      it "returns geojson with drawn polygon if it's been drawn" do
        create(:consultation, planning_application:, polygon_geojson: feature_collection.to_json)

        expect(planning_application.reload.neighbour_geojson).to eq(
          {
            "features" => [
              {
                "type" => "Feature",
                "properties" => {
                  color: "#d870fc"
                },
                "geometry" => {
                  "coordinates" => [[[10.0, 10.0], [30.0, 30.0], [20.0, 20.0], [20.0, 10.0], [20.0, 30.0], [10.0, 10.0]]],
                  "type" => "Polygon"
                }
              }
            ],
            "type" => "FeatureCollection"
          }
        )
      end

      it "returns boundary geojson if drawn polygon is not present" do
        create(:consultation, planning_application:)

        expect(planning_application.reload.neighbour_geojson).to eq(planning_application.boundary_geojson)
      end
    end
  end

  describe "#recommendation_options" do
    context "when householder" do
      let(:planning_application) { create(:planning_application, :planning_permission) }

      it "returns the right options" do
        expect(planning_application.application_type.decisions).to eq(["granted", "refused"])
      end
    end

    context "when LDC" do
      let(:planning_application) { create(:planning_application, :lawfulness_certificate) }

      it "returns the right options" do
        expect(planning_application.application_type.decisions).to eq(["granted", "refused"])
      end
    end

    context "when prior approval" do
      let(:planning_application) { create(:planning_application, :prior_approval) }

      it "returns the right options" do
        expect(planning_application.application_type.decisions).to eq(["granted", "not_required", "refused"])
      end
    end
  end
end
