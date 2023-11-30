# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherChangeValidationRequest do
  include_examples "ValidationRequest", described_class, "other_change_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:other_change_validation_request) }
  end

  describe "validations" do
    subject(:other_change_validation_request) { described_class.new }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { other_change_validation_request.planning_application = planning_application }

    describe "#reason" do
      it "validates presence" do
        expect do
          other_change_validation_request.valid?
        end.to change {
          other_change_validation_request.errors[:reason]
        }.to ["Provide a reason for changes"]
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
      it "does not validate for non fee items" do
        expect do
          create(:other_change_validation_request, planning_application:)
        end.not_to raise_error
      end
    end
  end

  describe "scopes" do
    describe "callbacks" do
      describe "::before_create #ensure_planning_application_not_validated!" do
        context "when a planning application has been validated" do
          let(:planning_application) { create(:planning_application, :in_assessment) }
          let(:other_change_validation_request) do
            create(:other_change_validation_request, planning_application:)
          end

          it "prevents an other_change_validation_request from being created" do
            expect do
              other_change_validation_request
            end.to raise_error(ValidationRequest::ValidationRequestNotCreatableError,
              "Cannot create Other Change Validation Request when planning application has been validated")
          end
        end
      end
    end
  end

  describe "events" do
    let!(:other_change_validation_request) { create(:other_change_validation_request, :open, applicant_response: "ok") }
    let!(:fee_item_validation_request) { create(:fee_change_validation_request, :open, applicant_response: "ok") }

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
