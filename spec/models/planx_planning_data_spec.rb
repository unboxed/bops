# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanxPlanningData do
  describe "validations" do
    subject(:planx_planning_data) { described_class.new }

    describe "#entry" do
      it "validates presence" do
        expect { planx_planning_data.valid? }.to change { planx_planning_data.errors[:entry] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { planx_planning_data.valid? }.to change { planx_planning_data.errors[:planning_application] }.to ["must exist"]
      end
    end
  end
end