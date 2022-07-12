# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest, type: :model do
  let(:request) { create(:additional_document_validation_request, :pending) }

  before { freeze_time }

  describe "states" do
    it "is initially in pending state" do
      expect(request).to be_pending
    end

    %w[additional_document other_change red_line_boundary_change
       replacement_document].each do |request_type|
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
          expect { request.mark_as_sent }.to change(request, :notified_at).from(nil).to(Time.zone.now.to_date)
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
        create(:red_line_boundary_change_validation_request, planning_application: planning_application)
      end

      let!(:planning_application) { create(:planning_application, :invalidated) }
      let!(:request2) { create(:red_line_boundary_change_validation_request, :post_validation, planning_application: planning_application) }

      it "returns post validation requests" do
        expect(RedLineBoundaryChangeValidationRequest.post_validation).to match_array(
          [request2]
        )
      end
    end
  end

  describe "callbacks" do
    describe "::after_create #email_and_timestamp" do
      let(:replacement_document_validation_request) { create(:replacement_document_validation_request, :pending, planning_application: planning_application) }
      let(:additional_document_validation_request) { create(:additional_document_validation_request, :pending, planning_application: planning_application) }
      let(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :pending, planning_application: planning_application) }
      let(:other_change_validation_request) { create(:replacement_document_validation_request, :pending, planning_application: planning_application) }
      let(:description_change_validation_request) { create(:description_change_validation_request, :pending, planning_application: planning_application) }

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
          let!(:request) do
            create(:other_change_validation_request, :open, fee_item: true, planning_application: planning_application)
          end

          it "resets the fee invalidation on the planning application" do
            request.assign_attributes(cancel_reason: "Cancel reason")

            expect do
              request.cancel_request!
            end.to change(request.planning_application, :valid_fee).from(false).to(nil)
          end
        end
      end

      describe "when there is an ActiveRecord error" do
        it "when no cancel reason it raises ValidationRequest::RecordCancelError" do
          expect { request.cancel_request! }
            .to raise_error(ValidationRequest::RecordCancelError, "Validation failed: Cancel reason can't be blank")
            .and change(Audit, :count).by(0)

          expect(request).to be_pending
          expect(request.cancelled_at).to eq(nil)
        end

        it "when request is in closed state it raises ValidationRequest::RecordCancelError" do
          request.update(state: "closed")
          request.assign_attributes(cancel_reason: "My bad")

          expect { request.cancel_request! }
            .to raise_error(ValidationRequest::RecordCancelError, "Event 'cancel' cannot transition from 'closed'.")
            .and change(Audit, :count).by(0)

          expect(request).to be_closed
          expect(request.cancelled_at).to eq(nil)
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

    describe "#active_closed_fee_item?" do
      context "when validation request does not respond to fee_item?" do
        let!(:validation_request) { create(:replacement_document_validation_request) }

        it "returns nil" do
          expect(validation_request.active_closed_fee_item?).to eq(nil)
        end
      end

      context "when fee_item is not true on the validation request" do
        let!(:validation_request) { create(:other_change_validation_request, fee_item: false) }

        it "returns false" do
          expect(validation_request.active_closed_fee_item?).to eq(false)
        end
      end

      context "when fee_item is true and validation request is not closed" do
        let!(:validation_request) { create(:other_change_validation_request, :open, fee_item: true) }

        it "returns false" do
          expect(validation_request.active_closed_fee_item?).to eq(false)
        end
      end

      context "when fee_item is true and validation request is closed" do
        let!(:planning_application) { create(:planning_application, :invalidated) }
        let!(:validation_request1) do
          create(:other_change_validation_request, :closed, fee_item: true, planning_application: planning_application)
        end
        let!(:validation_request2) do
          create(:other_change_validation_request, :closed, fee_item: true, planning_application: planning_application)
        end

        it "returns false when it is not the latest record" do
          expect(validation_request1.active_closed_fee_item?).to eq(false)
        end

        it "returns true when it is the latest record" do
          expect(validation_request2.active_closed_fee_item?).to eq(true)
        end
      end
    end

    describe "#auto_close_request!" do
      let(:request) { create(:red_line_boundary_change_validation_request, :open) }

      describe "when successful" do
        it "auto closes the request and creates an audit record" do
          expect { request.auto_close_request! }
            .to change(request, :auto_closed_at)
            .from(nil).to(Time.current)
            .and change(request, :state)
            .from("open").to("closed")
            .and change(request, :auto_closed).from(false).to(true)

          expect(Audit.last).to have_attributes(
            planning_application_id: request.planning_application.id,
            activity_type: "auto_closed"
          )
        end
      end

      describe "when there is an AASM::InvalidTransition error" do
        let!(:request) { create(:red_line_boundary_change_validation_request, :pending) }

        it "sends the error to Appsignal" do
          expect(Appsignal).to receive(:send_error).with("Event 'auto_close' cannot transition from 'pending'.")

          expect { request.auto_close_request! }
            .to change(Audit, :count).by(0)

          expect(request.reload).to be_pending
          expect(request.reload.auto_closed).to eq(false)
          expect(request.reload.auto_closed_at).to eq(nil)
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
            .to change(Audit, :count).by(0)

          expect(request.reload).to be_open
          expect(request.reload.auto_closed).to eq(false)
          expect(request.reload.auto_closed_at).to eq(nil)
          expect(request.reload.planning_application.boundary_geojson).not_to eq(request.reload.new_geojson)
        end
      end
    end
  end
end
