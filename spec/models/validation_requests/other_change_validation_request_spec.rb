# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest do
  it_behaves_like "ValidationRequest", described_class, "other_change_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:validation_request, :other_change) }
  end

  describe "validations" do
    subject(:other_change_validation_request) { build(:validation_request, :other_change, reason: "") }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { other_change_validation_request.planning_application = planning_application }

    describe "#reason" do
      it "validates presence" do
        expect do
          other_change_validation_request.valid?
        end.to change {
          other_change_validation_request.errors[:reason]
        }.to ["can't be blank"]
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #ensure_planning_application_not_validated!" do
      context "when a planning application has been validated" do
        let(:planning_application) { create(:planning_application, :in_assessment) }
        let(:other_change_validation_request) do
          create(:validation_request, :other_change, planning_application:)
        end

        it "prevents an other_change_validation_request from being created" do
          expect do
            other_change_validation_request
          end.to raise_error(ValidationRequest::ValidationRequestNotCreatableError,
            "Cannot create Other Change Validation Request when planning application has been validated")
        end
      end
    end

    describe "::before_create #reset_validation_requests_update_counter" do
      let(:local_authority) { create(:local_authority) }
      let!(:planning_application) { create(:planning_application, :invalidated, local_authority:) }

      before { other_change_validation_request1.close! }

      it "does not reset the update counter on the latest closed request" do
        expect(other_change_validation_request1.update_counter?).to be(true)
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
