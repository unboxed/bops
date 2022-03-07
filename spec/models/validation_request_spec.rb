# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest, type: :model do
  let(:request) { create(:additional_document_validation_request, state: "pending") }

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
      it_behaves_like "ValidationRequestStateMachineEvents", request_type, "open", %i[cancel auto_approve]
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
  end
end
