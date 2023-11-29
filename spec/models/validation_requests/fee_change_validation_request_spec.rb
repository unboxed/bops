# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest do
  it_behaves_like("Auditable") do
    subject { create(:validation_request, :fee_change) }
  end

  describe "validations" do
    subject(:fee_change_validation_request) { build(:validation_request, :fee_change, reason: "", specific_attributes: {suggestion: ""}) }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { fee_change_validation_request.planning_application = planning_application }

    describe "#reason" do
      it "validates presence" do
        expect do
          fee_change_validation_request.valid?
        end.to change {
          fee_change_validation_request.errors[:reason]
        }.to ["Provide a reason for changes"]
      end
    end

    describe "#suggestion" do
      it "validates presence" do
        expect do
          fee_change_validation_request.valid?
        end.to change {
          fee_change_validation_request.errors[:suggestion]
        }.to ["can't be blank"]
      end
    end

    describe "#ensure_no_open_or_pending_fee_item_validation_request" do
      before do
        create(:validation_request, :fee_change, :open, planning_application:)
      end

      it "validates that there is no open or pending fee validation request on create" do
        expect do
          create(:validation_request, :fee_change, planning_application:)
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: An open or pending fee validation request already exists for this planning application."
        )
      end

      it "does not validate for non fee items" do
        expect do
          create(:validation_request, :other_change, planning_application:)
        end.not_to raise_error
      end
    end
  end

  describe "scopes" do
    describe "callbacks" do
      describe "::before_update #reset_fee_invalidation" do
        let!(:planning_application) do
          create(:planning_application, :invalidated, valid_fee: false)
        end

        context "when it is a closed fee item validation request" do
          let!(:fee_change_validation_request) do
            create(:validation_request, :fee_change, :open, planning_application:)
          end

          before { fee_change_validation_request.update(state: "closed", applicant_response: "A response") }

          it "updates and resets the valid_fee to nil on the planning application" do
            expect(planning_application.reload.valid_fee).to be_nil
          end
        end

        context "when it is not a closed fee item validation request" do
          let!(:fee_change_validation_request) do
            create(:validation_request, :fee_change, :pending,
              planning_application:)
          end

          before { fee_change_validation_request.update(reason: "bla") }

          it "updates and resets the valid_fee to nil on the planning application" do
            expect(planning_application.reload.valid_fee).to be(false)
          end
        end
      end

      describe "::before_destroy #reset_fee_invalidation" do
        let!(:planning_application) do
          create(:planning_application, :not_started, valid_fee: false)
        end

        before do
          fee_change_validation_request.destroy!
        end

        context "when it is a fee item validation request" do
          let(:fee_change_validation_request) do
            create(:validation_request, :fee_change, :pending,
              planning_application:)
          end

          it "updates and resets the valid_fee to nil on the planning application" do
            expect(planning_application.reload.valid_fee).to be_nil
          end
        end

        context "when it is not a fee item validation request" do
          let(:fee_change_validation_request) do
            create(:validation_request, :other_change, :pending,
              planning_application:)
          end

          it "does not update the valid_fee on the planning application" do
            expect(planning_application.reload.valid_fee).to be(false)
          end
        end
      end

      describe "::after_create #set_invalid_payment_amount" do
        let!(:planning_application) do
          create(:planning_application, :not_started, payment_amount: 172.36)
        end

        context "when it is a fee item validation request" do
          let(:fee_change_validation_request) do
            create(:validation_request, :fee_change, :pending,
              planning_application:)
          end

          it "updates the invalid payment amount on the planning application" do
            expect do
              fee_change_validation_request
            end.to change(planning_application, :invalid_payment_amount).from(nil).to(172.36)
          end
        end
      end

      describe "::before_create #ensure_planning_application_not_validated!" do
        context "when a planning application has been validated" do
          let(:planning_application) { create(:planning_application, :in_assessment) }
          let(:fee_change_validation_request) do
            create(:validation_request, :fee_change, planning_application:)
          end

          it "prevents an fee_change_validation_request from being created" do
            expect do
              fee_change_validation_request
            end.to raise_error(ValidationRequest::ValidationRequestNotCreatableError,
              "Cannot create Fee Change Validation Request when planning application has been validated")
          end
        end
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #reset_validation_requests_update_counter" do
      let(:local_authority) { create(:local_authority) }
      let!(:planning_application) { create(:planning_application, :invalidated, local_authority:) }
      let(:fee_item_validation_request1) { create(:validation_request, :fee_change, :open, planning_application:, applicant_response: "ok") }
      let(:fee_item_validation_request2) { create(:validation_request, :fee_change, :open, planning_application:, applicant_response: "ok") }

      context "when there is a closed fee item change request and a new request is made" do
        before { fee_item_validation_request1.close! }

        it "resets the update counter on the latest closed request" do
          expect(fee_item_validation_request1.update_counter?).to be(true)

          fee_item_validation_request2

          expect(fee_item_validation_request1.reload.update_counter?).to be(false)
        end
      end
    end
  end

  describe "events" do
    let!(:fee_change_validation_request) { create(:validation_request, :fee_change, :open, applicant_response: "ok") }
    let!(:fee_item_validation_request) { create(:validation_request, :fee_change, :open, applicant_response: "ok") }

    describe "#close" do
      it "sets updated_counter to true on the associated validation request" do
        fee_change_validation_request.close!
        fee_item_validation_request.close!

        expect(fee_change_validation_request.update_counter?).to be(true)
        expect(fee_item_validation_request.update_counter?).to be(true)
      end
    end
  end
end
