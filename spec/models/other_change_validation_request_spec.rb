# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherChangeValidationRequest do
  it_behaves_like "ValidationRequest", described_class, "other_change_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:other_change_validation_request) }
  end

  describe "validations" do
    subject(:other_change_validation_request) { described_class.new }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { other_change_validation_request.planning_application = planning_application }

    describe "#summary" do
      it "validates presence" do
        expect do
          other_change_validation_request.valid?
        end.to change {
          other_change_validation_request.errors[:summary]
        }.to ["can't be blank"]
      end
    end

    describe "#suggestion" do
      it "validates presence" do
        expect do
          other_change_validation_request.valid?
        end.to change {
          other_change_validation_request.errors[:suggestion]
        }.to ["can't be blank"]
      end
    end

    describe "#ensure_no_open_or_pending_fee_item_validation_request" do
      before do
        create(:other_change_validation_request, :open, fee_item: true, planning_application: planning_application)
      end

      it "validates that there is no open or pending fee validation request on create" do
        expect do
          create(:other_change_validation_request, fee_item: true, planning_application: planning_application)
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: An open or pending fee validation request already exists for this planning application."
        )
      end

      it "does not validate for non fee items" do
        expect do
          create(:other_change_validation_request, planning_application: planning_application)
        end.not_to raise_error
      end
    end
  end

  describe "scopes" do
    describe ".fee_item" do
      before do
        create(:other_change_validation_request, fee_item: false)
      end

      let!(:other_change_validation_request1) do
        create(:other_change_validation_request, fee_item: true)
      end
      let!(:other_change_validation_request2) do
        create(:other_change_validation_request, fee_item: true)
      end

      it "returns other_change_validation_request where fee_item is set to true" do
        expect(described_class.fee_item).to match_array(
          [other_change_validation_request1, other_change_validation_request2]
        )
      end
    end

    describe ".non_fee_item" do
      before do
        create(:other_change_validation_request, fee_item: true)
      end

      let!(:other_change_validation_request1) do
        create(:other_change_validation_request, fee_item: false)
      end
      let!(:other_change_validation_request2) do
        create(:other_change_validation_request, fee_item: false)
      end

      it "returns other_change_validation_request where fee_item is set to false" do
        expect(described_class.non_fee_item).to match_array(
          [other_change_validation_request1, other_change_validation_request2]
        )
      end
    end

    describe "callbacks" do
      describe "::before_update #reset_fee_invalidation" do
        let!(:planning_application) do
          create(:planning_application, :invalidated, valid_fee: false)
        end

        context "when it is a closed fee item validation request" do
          let!(:other_change_validation_request) do
            create(:other_change_validation_request, :open, fee_item: true, planning_application: planning_application)
          end

          before { other_change_validation_request.update(state: "closed", response: "A response") }

          it "updates and resets the valid_fee to nil on the planning application" do
            expect(planning_application.reload.valid_fee).to be_nil
          end
        end

        context "when it is not a closed fee item validation request" do
          let!(:other_change_validation_request) do
            create(:other_change_validation_request, :pending, fee_item: true,
                                                               planning_application: planning_application)
          end

          before { other_change_validation_request.update(summary: "bla") }

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
          other_change_validation_request.destroy!
        end

        context "when it is a fee item validation request" do
          let(:other_change_validation_request) do
            create(:other_change_validation_request, :pending, fee_item: true,
                                                               planning_application: planning_application)
          end

          it "updates and resets the valid_fee to nil on the planning application" do
            expect(planning_application.reload.valid_fee).to be_nil
          end
        end

        context "when it is not a fee item validation request" do
          let(:other_change_validation_request) do
            create(:other_change_validation_request, :pending, fee_item: false,
                                                               planning_application: planning_application)
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
          let(:other_change_validation_request) do
            create(:other_change_validation_request, :pending, fee_item: true,
                                                               planning_application: planning_application)
          end

          it "updates the invalid payment amount on the planning application" do
            expect do
              other_change_validation_request
            end.to change(planning_application, :invalid_payment_amount).from(nil).to(172.36)
          end
        end

        context "when it is not a fee item validation request" do
          let(:other_change_validation_request) do
            create(:other_change_validation_request, :pending, fee_item: false,
                                                               planning_application: planning_application)
          end

          it "does not update the invalid payment amount on the planning application" do
            expect do
              other_change_validation_request
            end.not_to change(planning_application, :invalid_payment_amount)
          end
        end
      end

      describe "::before_create #ensure_planning_application_not_validated!" do
        context "when a planning application has been validated" do
          let(:planning_application) { create(:planning_application, :in_assessment) }
          let(:other_change_validation_request) do
            create(:other_change_validation_request, planning_application: planning_application)
          end

          it "prevents an other_change_validation_request from being created" do
            expect do
              other_change_validation_request
            end.to raise_error(ValidationRequestable::ValidationRequestNotCreatableError,
                               "Cannot create Other Change Validation Request when planning application has been validated")
          end
        end
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #reset_validation_requests_update_counter" do
      let(:local_authority) { create(:local_authority) }
      let!(:planning_application) { create(:planning_application, :invalidated, local_authority: local_authority) }
      let(:fee_item_validation_request1) { create(:other_change_validation_request, :open, :fee, planning_application: planning_application, response: "ok") }
      let(:fee_item_validation_request2) { create(:other_change_validation_request, :open, :fee, planning_application: planning_application, response: "ok") }

      context "when there is a closed fee item change request and a new request is made" do
        before { fee_item_validation_request1.close! }

        it "resets the update counter on the latest closed request" do
          expect(fee_item_validation_request1.update_counter?).to be(true)

          fee_item_validation_request2

          expect(fee_item_validation_request1.reload.update_counter?).to be(false)
        end
      end

      context "when the request is not a fee item" do
        let(:other_change_validation_request1) { create(:other_change_validation_request, :open, planning_application: planning_application, response: "ok") }
        let(:other_change_validation_request2) { create(:other_change_validation_request, :open, planning_application: planning_application, response: "ok") }

        before { other_change_validation_request1.close! }

        it "does not reset the update counter on the latest closed request" do
          expect(other_change_validation_request1.update_counter?).to be(true)

          fee_item_validation_request2

          expect(other_change_validation_request1.reload.update_counter?).to be(true)
        end
      end
    end
  end

  describe "events" do
    let!(:other_change_validation_request) { create(:other_change_validation_request, :open, response: "ok") }
    let!(:fee_item_validation_request) { create(:other_change_validation_request, :fee, :open, response: "ok") }

    describe "#close" do
      it "sets updated_counter to true on the associated validation request" do
        other_change_validation_request.close!
        fee_item_validation_request.close!

        expect(other_change_validation_request.update_counter?).to be(true)
        expect(fee_item_validation_request.update_counter?).to be(true)
      end
    end
  end
end
