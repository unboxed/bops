# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::ItemsCounterPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }

  describe "#items_count" do
    context "when planning application is not started" do
      let(:planning_application) { create(:planning_application, :invalidated) }

      before do
        create(:replacement_document_validation_request, :pending, planning_application: planning_application)
        create(:other_change_validation_request, :fee, :pending, planning_application: planning_application)
        create(:additional_document_validation_request, :pending, planning_application: planning_application)
        create(:red_line_boundary_change_validation_request, :pending, planning_application: planning_application)
        create(:other_change_validation_request, :pending, planning_application: planning_application)
      end

      it "the items count hash returns the count of invalid and updated validation requests" do
        items_count_hash = presenter.items_count

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
      let!(:additional_document_validation_request) { create(:additional_document_validation_request, :open, planning_application: planning_application) }
      let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, planning_application: planning_application) }

      before do
        create(:replacement_document_validation_request, :open, planning_application: planning_application)
        create(:other_change_validation_request, :fee, :open, planning_application: planning_application)
        create(:other_change_validation_request, :open, planning_application: planning_application)
      end

      it "the items count hash returns the count of invalid and updated validation requests" do
        items_count_hash = presenter.items_count

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
          items_count_hash = presenter.items_count

          expect(items_count_hash).to eq(
            {
              invalid: "3",
              updated: "2"
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
          items_count_hash = presenter.items_count

          expect(items_count_hash).to eq(
            {
              invalid: "4",
              updated: "0"
            }
          )
        end
      end
    end
  end
end
