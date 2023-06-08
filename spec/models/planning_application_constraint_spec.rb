# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationConstraint do
  describe "validations" do
    subject(:planning_application_constraint) { described_class.new }

    describe "#constraint" do
      it "validates presence" do
        expect { planning_application_constraint.valid? }.to change { planning_application_constraint.errors[:constraint] }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { planning_application_constraint.valid? }.to change { planning_application_constraint.errors[:planning_application] }.to ["must exist"]
      end
    end
  end
end
