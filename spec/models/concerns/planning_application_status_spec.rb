# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationStatus do
  subject(:planning_application) { create(:planning_application) }

  describe "states" do
    let(:proposed_document1) do
      create(:document, :with_tags,
        planning_application:,
        numbers: "number")
    end

    let(:description_change_validation_request) do
      create(:description_change_validation_request, planning_application:, state: "open",
        created_at: 12.days.ago)
    end

    context "when pending" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "pending", %i[mark_accepted]
    end

    context "when not started" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "not_started", %i[return close withdraw]
    end

    context "when invalidated" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "invalidated", %i[start return close withdraw]
    end

    context "when in assessment" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "in_assessment",
        %i[start save_assessment return close withdraw]
    end

    context "when assessment in progress" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "assessment_in_progress",
        %i[save_assessment]
    end

    context "when awaiting determination" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "awaiting_determination",
        %i[determine request_correction return close withdraw withdraw_recommendation]
    end

    context "when determined" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "determined", %i[]
    end

    context "when returned" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "returned", %i[]
    end

    context "when withdrawn" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "withdrawn", %i[]
    end

    context "when closed" do
      it_behaves_like "PlanningApplicationStateMachineEvents", "closed", %i[]
    end

    context "when I start the application" do
      subject(:planning_application) { create(:planning_application, :not_started) }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(in_assessment_at: 1.hour.ago)
      end

      it "sets the status to in_assessment" do
        planning_application.update!(validated_at: Time.zone.today)
        planning_application.start
        expect(planning_application.status).to eq "in_assessment"
        expect(Audit.last.activity_type).to eq("started")
      end

      it "sets the timestamp for in_assessment_at to now" do
        freeze_time do
          planning_application.update!(validated_at: Time.zone.today)
          planning_application.start
          expect(planning_application.in_assessment_at).to eql(Time.zone.now)
        end
      end
    end

    describe "work_status" do
      subject(:planning_application) { create(:planning_application, :not_started) }

      let(:proposed_drawing1) do
        create(:document, :with_tags,
          planning_application:,
          numbers: "number")
      end

      it "sets work_status to proposed" do
        expect(planning_application.work_status).to eq "proposed"
      end

      it "allows the work status to be updated" do
        planning_application.update!(work_status: "existing")
        expect(planning_application.work_status).to eql("existing")
      end
    end

    context "when I return the application from invalidated" do
      subject(:planning_application) { create(:planning_application, :invalidated) }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(returned_at: 1.hour.ago)
      end

      it "sets the status to returned" do
        planning_application.return

        expect(planning_application.status).to eq "returned"
        expect(Audit.last.activity_type).to eq("returned")
      end

      it "sets the timestamp for returned_at to now" do
        freeze_time do
          planning_application.return
          expect(planning_application.returned_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I assess the application" do
      let(:planning_application) { create(:planning_application, decision: "granted") }

      it "sets the status to in_assessment" do
        planning_application.assess
        expect(planning_application.status).to eq "in_assessment"
      end

      it "sets the timestamp for in_assessment_at to now" do
        freeze_time do
          planning_application.assess
          expect(planning_application.in_assessment_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I invalidate the application from not_started" do
      subject(:planning_application) { create(:planning_application, :not_started) }

      before do
        create(
          :additional_document_validation_request,
          planning_application:,
          state: "pending"
        )
      end

      it "sets the status to invalidated" do
        planning_application.invalidate
        expect(planning_application.status).to eq "invalidated"
        expect(Audit.last.activity_type).to eq("invalidated")
      end

      it "sets the timestamp for invalidated_at to now" do
        freeze_time do
          planning_application.invalidate
          expect(planning_application.invalidated_at).to eql(Time.zone.now)
        end
      end
    end

    context "when request_correction is called it sets application to to_be_reviewed" do
      let(:user) { create(:user) }

      let(:planning_application) do
        create(
          :planning_application,
          :awaiting_determination,
          decision: "granted",
          user:
        )
      end

      before do
        # Set timestamp to differentiate from now
        planning_application.update(to_be_reviewed_at: 1.hour.ago)
      end

      it "sets the status to to_be_reviewed" do
        planning_application.request_correction
        expect(planning_application.status).to eq "to_be_reviewed"
      end

      it "sets the timestamp for to_be_reviewed to now" do
        freeze_time do
          planning_application.request_correction
          expect(planning_application.to_be_reviewed_at).to eql(Time.zone.now)
        end
      end

      it "sends notification to assigned user" do
        expect { planning_application.request_correction }
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

    context "when I determine the application" do
      subject(:planning_application) { create(:planning_application, :awaiting_determination, decision: "granted") }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(determined_at: 1.hour.ago)
      end

      it "sets the status to determined" do
        planning_application.determine
        expect(planning_application.status).to eq "determined"
        expect(Audit.last.activity_type).to eq("determined")
      end

      it "sets the timestamp for determined_at to now" do
        freeze_time do
          planning_application.determine
          expect(planning_application.determined_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I withdraw the application from not_started" do
      subject(:planning_application) { create(:planning_application, :not_started) }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(withdrawn_at: 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw

        expect(planning_application.status).to eq "withdrawn"
        expect(Audit.last.activity_type).to eq("withdrawn")
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.withdrawn_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I withdraw the application from in_assessment" do
      subject(:planning_application) { create(:planning_application) }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(withdrawn_at: 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw

        expect(planning_application.status).to eq "withdrawn"
        expect(Audit.last.activity_type).to eq("withdrawn")
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.withdrawn_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I withdraw the application from awaiting_determination" do
      subject(:planning_application) { create(:planning_application, :awaiting_determination, decision: "granted") }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(withdrawn_at: 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw

        expect(planning_application.status).to eq "withdrawn"
        expect(Audit.last.activity_type).to eq("withdrawn")
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.withdrawn_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I withdraw the application from to_be_reviewed" do
      subject(:planning_application) { create(:planning_application, :to_be_reviewed, decision: "granted") }

      before do
        # Set timestamp to differentiate from now
        planning_application.update(withdrawn_at: 1.hour.ago)
      end

      it "sets the status to withdrawn" do
        planning_application.withdraw

        expect(planning_application.status).to eq "withdrawn"
        expect(Audit.last.activity_type).to eq("withdrawn")
      end

      it "sets the timestamp for withdrawn_at to now" do
        freeze_time do
          planning_application.withdraw
          expect(planning_application.withdrawn_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I submit the application from in_assessment" do
      context "when decision is present" do
        let(:planning_application) do
          create(:planning_application, :with_recommendation, :in_assessment, decision: "granted")
        end

        it "sets the status to awaiting_determination" do
          planning_application.submit

          expect(planning_application.status).to eq("awaiting_determination")
        end

        it "sets the recommendation to submitted" do
          planning_application.submit

          expect(planning_application.recommendation.submitted).to be(true)
        end

        it "sets the timestamp for awaiting_determination_at to now" do
          freeze_time do
            planning_application.submit

            expect(planning_application.awaiting_determination_at).to eql(Time.zone.now)
          end
        end
      end

      context "when decision is not present" do
        let(:planning_application) { create(:planning_application, :in_assessment) }

        it "guards against decision not being present" do
          expect do
            planning_application.submit
          end.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    context "when I withdraw the recommendation from awaiting determination" do
      let(:planning_application) do
        create(:planning_application, :with_recommendation, :awaiting_determination, decision: "granted")
      end

      it "sets the status back to in_assessment" do
        planning_application.withdraw_recommendation

        expect(planning_application.status).to eq("in_assessment")
      end

      it "sets recommendation submitted to false" do
        planning_application.withdraw_recommendation

        expect(planning_application.recommendation.submitted).to be(false)
      end

      it "sets the timestamp for awaiting_determination_at to now" do
        freeze_time do
          planning_application.withdraw_recommendation

          expect(planning_application.in_assessment_at).to eql(Time.zone.now)
        end
      end
    end
  end
end
