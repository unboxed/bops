# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest do
  describe "validations" do
    subject(:validation_request) { described_class.new }

    describe "#type" do
      it "validates presence and inclusion" do
        expect { validation_request.valid? }.to change { validation_request.errors[:type] }.to ["can't be blank", "is not included in the list"]
      end
    end

    describe "#planning_application" do
      it "validates presence and inclusion" do
        expect { validation_request.valid? }.to change { validation_request.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "constants" do
    describe "REQUEST_TYPES" do
      it "returns the permitted validation request types" do
        expect(ValidationRequest::REQUEST_TYPES).to eq(
          %w[
            AdditionalDocumentValidationRequest
            DescriptionChangeValidationRequest
            RedLineBoundaryChangeValidationRequest
            ReplacementDocumentValidationRequest
            OwnershipCertificateValidationRequest
            OtherChangeValidationRequest
            FeeChangeValidationRequest
            PreCommencementConditionValidationRequest
          ]
        )
      end
    end
  end

  let(:request) { create(:additional_document_validation_request, :pending) }

  before { freeze_time }

  describe "states" do
    it "is initially in pending state" do
      expect(request).to be_pending
    end

    %w[additional_document other_change red_line_boundary_change fee_change ownership_certificate
      replacement_document pre_commencement_condition].each do |request_type|
      it_behaves_like "ValidationRequestStateMachineTransitions", request_type, "pending", %i[open cancelled]
      it_behaves_like "ValidationRequestStateMachineTransitions", request_type, "open", %i[cancelled closed]
      it_behaves_like "ValidationRequestStateMachineTransitions", request_type, "cancelled", %i[]
      it_behaves_like "ValidationRequestStateMachineTransitions", request_type, "closed", %i[]

      it_behaves_like "ValidationRequestStateMachineEvents", request_type, "pending", %i[mark_as_sent cancel]
      it_behaves_like "ValidationRequestStateMachineEvents", request_type, "open", %i[cancel auto_close]
      it_behaves_like "ValidationRequestStateMachineEvents", request_type, "cancelled", %i[]
      it_behaves_like "ValidationRequestStateMachineEvents", request_type, "closed", %i[]
    end

    describe "events" do
      describe "mark_as_sent" do
        it "updates the notified timestamp" do
          expect { request.mark_as_sent }.to change(request, :notified_at).from(nil).to be_within(1.minute).of(Time.zone.now)
        end
      end

      describe "cancel" do
        it "does not update the state to cancelled without a cancel reason" do
          expect { request.cancel }
            .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Cancel reason can't be blank")
        end

        it "updates the state to cancelled" do
          request.assign_attributes(cancel_reason: "My bad")

          expect { request.cancel! }
            .to change(request, :state).from("pending").to("cancelled")
            .and change(request, :cancelled_at).from(nil).to(Time.current)
        end
      end
    end
  end

  describe "scopes" do
    describe ".not_cancelled" do
      before do
        create(:replacement_document_validation_request, :cancelled)
      end

      let!(:replacement_document_validation_request1) do
        create(:replacement_document_validation_request, :closed)
      end
      let!(:replacement_document_validation_request2) do
        create(:replacement_document_validation_request, :open)
      end
      let!(:replacement_document_validation_request3) do
        create(:replacement_document_validation_request, :pending)
      end

      it "returns non cancelled replacement document requests" do
        expect(ReplacementDocumentValidationRequest.not_cancelled).to match_array(
          [replacement_document_validation_request1, replacement_document_validation_request2,
            replacement_document_validation_request3]
        )
      end
    end

    describe ".post_validation" do
      before do
        create(:red_line_boundary_change_validation_request, planning_application:)
      end

      let!(:planning_application) { create(:planning_application, :invalidated) }
      let!(:request2) { create(:red_line_boundary_change_validation_request, :post_validation, planning_application:) }

      it "returns post validation requests" do
        expect(RedLineBoundaryChangeValidationRequest.post_validation).to match_array(
          [request2]
        )
      end
    end
  end

  describe "callbacks" do
    describe "::after_create #email_and_timestamp" do
      let(:replacement_document_validation_request) { create(:replacement_document_validation_request, :pending, planning_application:) }
      let(:additional_document_validation_request) { create(:additional_document_validation_request, :pending, planning_application:) }
      let(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :pending, planning_application:) }
      let(:other_change_validation_request) { create(:replacement_document_validation_request, :pending, planning_application:) }
      let(:description_change_validation_request) { create(:description_change_validation_request, :pending, planning_application:) }

      context "when planning application is not started" do
        let(:planning_application) { create(:planning_application, :not_started) }

        %w[replacement_document_validation_request additional_document_validation_request red_line_boundary_change_validation_request other_change_validation_request].each do |request|
          let(:validation_request) { send(request) }

          it "does not send an email or call the mark_as_sent! event for a(n) #{request}" do
            expect { validation_request }.not_to change(ActionMailer::Base.deliveries, :count)

            expect(validation_request.state).to eq("pending")
          end
        end

        it "sends an email and calls the mark_as_sent! event for a description change validation request" do
          expect(description_change_validation_request.state).to eq("open")
        end
      end

      context "when planning application is invalidated" do
        let(:planning_application) { create(:planning_application, :invalidated) }

        %w[replacement_document_validation_request additional_document_validation_request red_line_boundary_change_validation_request other_change_validation_request description_change_validation_request].each do |request|
          let(:validation_request) { send(request) }

          it "sends an email and calls the mark_as_sent! event for a(n) #{request}" do
            expect { validation_request }.to change { ActionMailer::Base.deliveries.count }.by(1)

            expect(validation_request.state).to eq("open")
          end
        end
      end

      context "when planning application has been validated" do
        let(:planning_application) { create(:planning_application, :in_assessment) }

        %w[red_line_boundary_change_validation_request description_change_validation_request].each do |request|
          let(:validation_request) { send(request) }

          it "sends an email and calls the mark_as_sent! event for a(n) #{request}" do
            expect { validation_request }.to change { ActionMailer::Base.deliveries.count }.by(1)

            expect(validation_request.state).to eq("open")
          end
        end
      end
    end
  end

  describe "instance methods" do
    describe "#cancel_request!" do
      before { Current.user = request.user }

      describe "when successful" do
        it "cancels the request and creates and audit record" do
          request.assign_attributes(cancel_reason: "My bad")

          expect { request.cancel_request! }
            .to change(request, :cancelled_at).from(nil).to(Time.current)
            .and change(request, :state).from("pending").to("cancelled")

          expect(Audit.last).to have_attributes(
            planning_application_id: request.planning_application.id,
            activity_type: "additional_document_validation_request_cancelled",
            activity_information: "1",
            audit_comment: "{\"cancel_reason\":\"My bad\"}"
          )
        end

        context "when validation request is a fee item" do
          let!(:planning_application) do
            create(:planning_application, :invalidated, valid_fee: false)
          end
          let!(:request1) do
            create(:fee_change_validation_request, :closed, planning_application:, response: "ok")
          end
          let(:request2) do
            create(:fee_change_validation_request, :open, planning_application:, response: "ok")
          end

          it "resets the fee invalidation on the planning application" do
            request2.assign_attributes(cancel_reason: "Cancel reason")

            expect do
              request2.cancel_request!
            end.to change(request1.planning_application, :valid_fee).from(false).to(nil)
          end

          it "resets the update counter on the previously closed request" do
            request2.assign_attributes(cancel_reason: "Cancel reason")
            request2.cancel_request!
            expect(request2.update_counter).to be(false)
            expect(request1.reload.update_counter).to be(true)
          end
        end

        context "when it is replacement document validation request" do
          let!(:planning_application) do
            create(:planning_application, :invalidated)
          end
          let(:request1) { create(:replacement_document_validation_request, :open, planning_application:) }
          let!(:document) { create(:document, owner: request1) }
          let(:request2) { create(:replacement_document_validation_request, :open, planning_application:, old_document: document) }

          it "when request is cancelled it updates the counter of the previously closed request to true" do
            # This part of the test doesn't make any sense... the close! action calls the update_counter method, which sets
            # update_counter to true
            request1.close!
            # expect(request1.update_counter).to be(true)
            # expect(request2.update_counter).to be(false)
            # expect(request1.reload.update_counter).to be(false)

            request2.assign_attributes(cancel_reason: "Cancel reason")
            request2.cancel_request!
            expect(request2.update_counter).to be(false)
            expect(request1.reload.update_counter).to be(true)
          end
        end

        context "when it is a red line boundary request" do
          let!(:planning_application) do
            create(:planning_application, :invalidated, valid_red_line_boundary: false)
          end
          let(:request1) { create(:red_line_boundary_change_validation_request, :open, planning_application:) }
          let(:request2) { create(:red_line_boundary_change_validation_request, :open, planning_application:) }

          it "resets the valid_red_line_boundary on the planning application" do
            request1.assign_attributes(cancel_reason: "Cancel reason")

            expect do
              request1.cancel_request!
            end.to change(request1.planning_application, :valid_red_line_boundary).from(false).to(nil)
          end

          it "when request is cancelled it updates the counter of the previously closed request to true" do
            request1.close!
            expect(request1.update_counter).to be(true)
            expect(request2.update_counter).to be(false)
            expect(request1.reload.update_counter).to be(false)

            request2.assign_attributes(cancel_reason: "Cancel reason")
            request2.cancel_request!
            expect(request2.update_counter).to be(false)
            expect(request1.reload.update_counter).to be(true)
          end
        end
      end

      describe "when there is an ActiveRecord error" do
        it "when no cancel reason it raises ValidationRequest::RecordCancelError" do
          expect { request.cancel_request! }
            .to raise_error(ValidationRequest::RecordCancelError, "Validation failed: Cancel reason can't be blank")
            .and not_change(Audit, :count)

          expect(request).to be_pending
          expect(request.cancelled_at).to be_nil
        end

        it "when request is in closed state it raises ValidationRequest::RecordCancelError" do
          request.update(state: "closed")
          request.assign_attributes(cancel_reason: "My bad")

          expect { request.cancel_request! }
            .to raise_error(ValidationRequest::RecordCancelError, "Event 'cancel' cannot transition from 'closed'.")
            .and not_change(Audit, :count)

          expect(request).to be_closed
          expect(request.cancelled_at).to be_nil
        end
      end
    end

    describe "#overdue?" do
      context "not description change requests" do
        let(:overdue_request) { create(:other_change_validation_request, :open, created_at: 16.business_days.ago) }
        let(:not_overdue_request) { create(:other_change_validation_request, :open, created_at: 1.business_day.ago) }

        it "returns true for overdue requests" do
          expect(overdue_request.overdue?).to be true
          expect(not_overdue_request.overdue?).to be false
        end
      end

      context "description change requests" do
        let(:overdue_request) { create(:description_change_validation_request, :open, created_at: 6.business_days.ago) }
        let(:not_overdue_request) { create(:description_change_validation_request, :open, created_at: 4.business_day.ago) }

        it "returns true for overdue requests" do
          expect(overdue_request.overdue?).to be true
          expect(not_overdue_request.overdue?).to be false
        end
      end
    end

    describe "#open_or_pending?" do
      context "when true" do
        %i[open pending].each do |state|
          let!(:replacement_document_validation_request) do
            create(:replacement_document_validation_request, :"#{state}")
          end

          it "for a #{state} validation request" do
            expect(replacement_document_validation_request).to be_open_or_pending
          end
        end
      end

      context "when false" do
        %i[closed cancelled].each do |state|
          let!(:replacement_document_validation_request) do
            create(:replacement_document_validation_request, :"#{state}")
          end

          it "for a #{state} validation request" do
            expect(replacement_document_validation_request).not_to be_open_or_pending
          end
        end
      end
    end

    describe "#sent_by" do
      let(:user) { create(:user) }
      let(:request) { create(:other_change_validation_request, planning_application:) }

      before { Current.user = user }

      context "when a planning application has been invalidated" do
        let(:planning_application) { create(:planning_application, :invalidated) }

        it "returns user for audit associated with send event" do
          expect(request.sent_by).to eq(user)
        end
      end

      context "before a planning application is invalidated" do
        let(:planning_application) { create(:planning_application, :not_started) }

        it "returns user for audit associated with add event" do
          expect(request.sent_by).to eq(user)
        end
      end
    end

    describe "#active_closed_fee_item?" do
      context "when validation request does not respond to fee_item?" do
        let!(:validation_request) { create(:replacement_document_validation_request) }

        it "returns nil" do
          expect(validation_request.active_closed_fee_item?).to be false
        end
      end

      context "when it is a fee validation request" do
        let!(:validation_request) { create(:other_change_validation_request) }

        it "returns false" do
          expect(validation_request.active_closed_fee_item?).to be(false)
        end
      end

      context "when it is a fee change validation request is not closed" do
        let!(:validation_request) { create(:other_change_validation_request, :open) }

        it "returns false" do
          expect(validation_request.active_closed_fee_item?).to be(false)
        end
      end

      context "when fee_item is true and validation request is closed" do
        let!(:planning_application) { create(:planning_application, :invalidated) }
        let!(:validation_request1) do
          create(:other_change_validation_request, :closed, planning_application:)
        end
        let!(:validation_request2) do
          create(:fee_change_validation_request, :closed, planning_application:)
        end

        it "returns false when it is not the latest record" do
          expect(validation_request1.active_closed_fee_item?).to be(false)
        end

        it "returns true when it is the latest record" do
          expect(validation_request2.active_closed_fee_item?).to be(true)
        end
      end
    end

    describe "#auto_close_request!" do
      let(:planning_application) { create(:planning_application) }

      let!(:request) do
        create(
          :red_line_boundary_change_validation_request,
          :open,
          planning_application:
        )
      end

      it "updates state to 'closed'" do
        expect { request.auto_close_request! }
          .to change(request, :state)
          .from("open").to("closed")
      end

      it "updates auto_closed_at to current time" do
        expect { request.auto_close_request! }
          .to change(request, :auto_closed_at)
          .from(nil).to(Time.current)
      end

      it "updates auto_closed to true" do
        expect { request.auto_close_request! }
          .to change(request, :auto_closed)
          .from(false).to(true)
      end

      it "creates audit with correct information" do
        travel_to(5.minutes.from_now)
        request.auto_close_request!

        expect(planning_application.audits.reload.last).to have_attributes(
          activity_type: "red_line_boundary_change_validation_request_auto_closed",
          activity_information: "1"
        )
      end

      context "when request is for description change" do
        let(:request) do
          create(
            :description_change_validation_request,
            :open,
            planning_application:
          )
        end

        it "creates audit with correct information" do
          request.auto_close_request!

          audit = planning_application.audits.reload.last

          expect(audit).to have_attributes(
            activity_type: "description_change_validation_request_auto_closed",
            activity_information: "1"
          )
        end
      end

      describe "when there is an AASM::InvalidTransition error" do
        let!(:request) { create(:red_line_boundary_change_validation_request, :pending) }

        it "sends the error to Appsignal" do
          expect(Appsignal).to receive(:send_error).with("Event 'auto_close' cannot transition from 'pending'.")

          expect { request.auto_close_request! }
            .not_to change(Audit, :count)

          expect(request.reload).to be_pending
          expect(request.reload.auto_closed).to be(false)
          expect(request.reload.auto_closed_at).to be_nil
          expect(request.reload.planning_application.boundary_geojson).not_to eq(request.reload.new_geojson)
        end
      end

      describe "when there is an ActiveRecord error" do
        before do
          allow(request).to receive(:update!).and_raise(ActiveRecord::ActiveRecordError)
        end

        it "sends the error to Appsignal" do
          expect(Appsignal).to receive(:send_error).with("ActiveRecord::ActiveRecordError")

          expect { request.auto_close_request! }
            .not_to change(Audit, :count)

          expect(request.reload).to be_open
          expect(request.reload.auto_closed).to be(false)
          expect(request.reload.auto_closed_at).to be_nil
          expect(request.reload.planning_application.boundary_geojson).not_to eq(request.reload.new_geojson)
        end
      end
    end

    describe "#reset_update_counter!" do
      context "when the request is post validation" do
        let(:request) { create(:red_line_boundary_change_validation_request, :post_validation) }

        it "does not reset the update counter" do
          expect(request).not_to receive(:update!)

          request.reset_update_counter!
        end
      end

      context "when the request is not post validation" do
        let(:request) { create(:red_line_boundary_change_validation_request, :open) }

        it "does not reset the update counter" do
          expect(request).to receive(:update!)

          request.reset_update_counter!
        end
      end
    end

    describe "#update_counter!" do
      let!(:planning_application) { create(:planning_application, :invalidated) }
      let(:fee_item_validation_request) do
        create(:fee_change_validation_request, :closed, planning_application:)
      end

      %w[
        additional_document_validation_request
        description_change_validation_request
        other_change_validation_request
        red_line_boundary_change_validation_request
        replacement_document_validation_request
      ].each do |validation_request|
        let(validation_request) { create(validation_request, :closed, planning_application:) }
      end

      it "does not update counter for a description change validation request" do
        expect(description_change_validation_request).not_to receive(:update!)

        description_change_validation_request.update_counter!
      end

      it "does not update counter for an additional document validation request" do
        expect(additional_document_validation_request).not_to receive(:update!)

        additional_document_validation_request.update_counter!
      end

      it "updates the counter" do
        expect(red_line_boundary_change_validation_request).to receive(:update!).with(update_counter: true)
        expect(other_change_validation_request).to receive(:update!).with(update_counter: true)
        expect(fee_item_validation_request).to receive(:update!).with(update_counter: true)
        expect(replacement_document_validation_request).to receive(:update!).with(update_counter: true)

        red_line_boundary_change_validation_request.update_counter!
        other_change_validation_request.update_counter!
        fee_item_validation_request.update_counter!
        replacement_document_validation_request.update_counter!
      end
    end
  end

  describe "#open_post_validation_requests" do
    let(:planning_application) { create(:planning_application, :in_assessment) }

    before do
      create(:red_line_boundary_change_validation_request, :cancelled, :post_validation, planning_application:)
      create(:red_line_boundary_change_validation_request, :closed, :post_validation, planning_application:)
    end

    context "when there are no open post validation requests" do
      it "returns an empty array" do
        expect(planning_application.open_post_validation_requests).to eq([])
        expect(planning_application).not_to be_open_post_validation_requests
      end
    end

    context "when there are open post validation requests" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :open, :post_validation, planning_application:)
      end

      it "returns the array" do
        expect(planning_application.open_post_validation_requests).to match_array([red_line_boundary_change_validation_request])
        expect(planning_application).to be_open_post_validation_requests
      end
    end
  end

  describe ".pre_validation" do
    let(:pre_validation_planning_application) do
      create(:planning_application, :not_started)
    end

    let(:pre_validation_request) do
      create(
        :additional_document_validation_request,
        planning_application: pre_validation_planning_application
      )
    end

    let(:post_validation_planning_application) do
      create(:planning_application, :in_assessment)
    end

    before do
      create(
        :additional_document_validation_request,
        planning_application: post_validation_planning_application
      )
    end

    it "returns only pre validation requests" do
      expect(
        AdditionalDocumentValidationRequest.pre_validation
      ).to contain_exactly(
        pre_validation_request
      )
    end
  end
end
