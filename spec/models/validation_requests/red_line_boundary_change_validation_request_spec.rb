# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest do
  it_behaves_like("Auditable") do
    subject { create(:validation_request, :red_line_boundary_change) }
  end

  describe "validations" do
    subject(:red_line_boundary_change_validation_request) { build(:validation_request, :red_line_boundary_change, reason: "", specific_attributes: {new_geojson: {}}) }

    describe "#new_geojson" do
      it "validates presence" do
        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:new_geojson]
        }.to ["Red line drawing must be complete"]
      end
    end

    describe "#reason" do
      it "validates presence" do
        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:reason]
        }.to ["Provide a reason for changes"]
      end
    end

    describe "#rejection_reason" do
      it "validates presence when approved is set to false" do
        red_line_boundary_change_validation_request = described_class.new(applicant_approved: false)

        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:base]
        }.to ["Please include a comment for the case officer to indicate why the red line boundary change has been rejected."]
      end
    end
  end

  describe "callbacks" do
    let(:red_line_boundary_change_validation_request) { create(:validation_request, :red_line_boundary_change) }

    describe "::before_create #set_original_geojson" do
      it "sets the original geojson field using the planning application boundary geojson" do
        planning_application = create(:planning_application, :invalidated, :with_boundary_geojson)
        red_line_boundary_change_validation_request = create(:validation_request, :red_line_boundary_change,
          planning_application:)

        expect(red_line_boundary_change_validation_request.original_geojson).to eq(planning_application.boundary_geojson)
      end
    end

    describe "::before_create #reset_validation_requests_update_counter" do
      let(:local_authority) { create(:local_authority) }
      let!(:planning_application) { create(:planning_application, :invalidated, local_authority:) }
      let(:red_line_boundary_change_validation_request1) { create(:validation_request, :red_line_boundary_change, :open, planning_application:) }
      let(:red_line_boundary_change_validation_request2) { create(:validation_request, :red_line_boundary_change, :open, planning_application:) }

      context "when there is a closed red line boundary change request and another request is made" do
        before { red_line_boundary_change_validation_request1.close! }

        it "resets the update counter on the latest closed request" do
          expect(red_line_boundary_change_validation_request1.update_counter?).to be(true)

          red_line_boundary_change_validation_request2

          expect(red_line_boundary_change_validation_request1.reload.update_counter?).to be(false)
        end
      end
    end

    describe "::after_create #set_post_validation" do
      context "when a planning application has not been validated" do
        let(:planning_application) { create(:planning_application, :not_started) }
        let(:red_line_boundary_change_validation_request) { create(:validation_request, :red_line_boundary_change, planning_application:) }

        it "does not set post validation to true on a red line boundary validation request" do
          expect(red_line_boundary_change_validation_request.post_validation).to be_falsey
        end
      end

      context "when a planning application has been validated" do
        let(:planning_application) { create(:planning_application, :in_assessment) }
        let(:red_line_boundary_change_validation_request) { create(:validation_request, :red_line_boundary_change, planning_application:) }

        it "sets post validation to true on a red line boundary validation request" do
          expect(red_line_boundary_change_validation_request.post_validation).to be_truthy
        end
      end
    end
  end

  describe "events" do
    let!(:red_line_boundary_change_validation_request) { create(:validation_request, :red_line_boundary_change, :open) }

    describe "#close" do
      it "sets updated_counter to true on the associated validation request" do
        red_line_boundary_change_validation_request.close!

        expect(red_line_boundary_change_validation_request.update_counter?).to be(true)
      end
    end
  end
end
