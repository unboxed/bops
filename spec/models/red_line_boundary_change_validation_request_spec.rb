# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedLineBoundaryChangeValidationRequest, type: :model do
  # rubocop:disable Layout/LineLength
  it_behaves_like "ValidationRequest", described_class, "red_line_boundary_change_validation_request"

  describe "validations" do
    subject(:red_line_boundary_change_validation_request) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:planning_application]
        }.to ["must exist"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:user]
        }.to ["must exist"]
      end
    end

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
        red_line_boundary_change_validation_request = described_class.new(approved: false)

        expect do
          red_line_boundary_change_validation_request.valid?
        end.to change {
          red_line_boundary_change_validation_request.errors[:base]
        }.to ["Please include a comment for the case officer to indicate why the red line boundary change has been rejected."]
      end
    end
  end

  describe "callbacks" do
    let(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request) }

    describe "::before_create" do
      it "sets the original geojson field using the planning application boundary geojson" do
        planning_application = create(:planning_application, :with_boundary_geojson)
        red_line_boundary_change_validation_request = create(:red_line_boundary_change_validation_request,
                                                             planning_application: planning_application)

        expect(red_line_boundary_change_validation_request.original_geojson).to eq(planning_application.boundary_geojson)
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
