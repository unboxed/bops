# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanxPlanningData do
  describe "validations" do
    subject(:planx_planning_data) { described_class.new(session_id: "12345678") }

    describe "#planning_application" do
      it "validates presence" do
        expect { planx_planning_data.valid? }.to change { planx_planning_data.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#session_id" do
      it "validates uniqueness" do
        create(:planx_planning_data, session_id: "12345678")

        expect { create(:planx_planning_data, session_id: "12345678") }.to raise_error(
          ActiveRecord::RecordInvalid, "Validation failed: Session has already been taken"
        )
      end
    end
  end
end
