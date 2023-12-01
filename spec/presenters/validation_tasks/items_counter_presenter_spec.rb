# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::ItemsCounterPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }

  let(:planning_application) { create(:planning_application, :invalidated) }

  describe "#items_count" do
    context "when planning application is not started" do
      let(:planning_application) { create(:planning_application, :not_started) }

      before do
        create(:replacement_document_validation_request, :pending, planning_application:)
        create(:fee_change_validation_request, :pending, planning_application:)
        create(:additional_document_validation_request, :pending, planning_application:)
        create(:red_line_boundary_change_validation_request, :pending, planning_application:)
        create(:other_change_validation_request, :pending, planning_application:)
      end

      it "the items count hash returns the count of invalid and updated validation requests" do
        expect(items_count_hash).to eq(
          {
            invalid: "5",
            updated: "0"
          }
        )
      end
    end

    context "when planning application is invalidated" do
      let(:planning_application) { create(:planning_application, :invalidated) }
      let!(:additional_document_validation_request) { create(:additional_document_validation_request, :open, planning_application:) }
      let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, planning_application:) }

      before do
        create(:fee_change_validation_request, :open, planning_application:, applicant_response: "ok")
        create(:replacement_document_validation_request, :open, planning_application:)
        create(:other_change_validation_request, :open, planning_application:)
      end

      it "the items count hash returns the count of invalid and updated validation requests" do
        expect(items_count_hash).to eq(
          {
            invalid: "5",
            updated: "0"
          }
        )
      end

      context "when some validation requests are closed" do
        before do
          additional_document_validation_request.close!
          red_line_boundary_change_validation_request.close!
        end

        it "the items count hash returns the count of invalid and updated validation requests" do
          expect(items_count_hash).to eq(
            {
              invalid: "3",
              updated: "1"
            }
          )
        end
      end

      context "when an open validation request is cancelled" do
        before do
          additional_document_validation_request.assign_attributes(cancel_reason: "Not needed anymore")
          additional_document_validation_request.cancel!
        end

        it "the items count hash returns the count of invalid and updated validation requests" do
          expect(items_count_hash).to eq(
            {
              invalid: "4",
              updated: "0"
            }
          )
        end
      end
    end

    context "when there are multiple red line boundary requests" do
      let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, planning_application:) }

      before do
        red_line_boundary_change_validation_request.close!
        create(:red_line_boundary_change_validation_request, :open, planning_application:)
      end

      it "the updated count only includes the latest closed red line boundary change validation request" do
        RedLineBoundaryChangeValidationRequest.last.close!

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "1"
          }
        )
      end

      it "the updated count does not include a previous closed request when the latest request is open" do
        expect(items_count_hash).to eq(
          {
            invalid: "1",
            updated: "0"
          }
        )
      end

      it "when red line boundary is made valid it resets the update counter" do
        RedLineBoundaryChangeValidationRequest.last.close!
        planning_application.update!(valid_red_line_boundary: true)

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "0"
          }
        )
      end
    end

    context "when there are multiple fee item validation requests" do
      let!(:fee_item_validation_request) { create(:fee_change_validation_request, :open, planning_application:, applicant_response: "ok") }

      before do
        fee_item_validation_request.close!
        create(:fee_change_validation_request, :open, planning_application:, applicant_response: "ok")
      end

      it "the updated count only includes the latest closed fee item change validation request" do
        FeeChangeValidationRequest.open.last.close!

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "1"
          }
        )
      end

      it "the updated count does not include a previous closed request when the latest request is open" do
        expect(items_count_hash).to eq(
          {
            invalid: "1",
            updated: "0"
          }
        )
      end

      it "when fee is made valid it resets the update counter" do
        FeeChangeValidationRequest.last.close!
        planning_application.update!(valid_fee: true)

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "0"
          }
        )
      end
    end

    context "when there are multiple other validation requests" do
      let!(:other_change_validation_request) { create(:other_change_validation_request, :open, planning_application:, applicant_response: "ok") }

      before do
        other_change_validation_request.close!
        create(:other_change_validation_request, :open, planning_application:, applicant_response: "ok")
      end

      it "the updated count includes all the closed other change validation requests" do
        OtherChangeValidationRequest.last.close!

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "2"
          }
        )
      end

      it "the updated count includes the previous closed and latest open other change validation request" do
        expect(items_count_hash).to eq(
          {
            invalid: "1",
            updated: "1"
          }
        )
      end
    end

    context "when there are multiple replacement document validation requests" do
      let!(:replacement_document_validation_request) { create(:replacement_document_validation_request, :open, planning_application:) }

      before do
        replacement_document_validation_request.close!
        create(:replacement_document_validation_request, :open, planning_application:)
      end

      it "the updated count includes all the closed replacement document requests" do
        ReplacementDocumentValidationRequest.last.close!

        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "2"
          }
        )
      end

      it "the updated count includes the previous closed and latest open other change validation request" do
        expect(items_count_hash).to eq(
          {
            invalid: "1",
            updated: "1"
          }
        )
      end
    end

    context "when there are no invalid or updated requests" do
      it "the displays no count" do
        expect(items_count_hash).to eq(
          {
            invalid: "0",
            updated: "0"
          }
        )
      end
    end
  end
end

def items_count_hash
  presenter.items_count
end
