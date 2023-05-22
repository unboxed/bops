# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationConstraintsQuery do
  describe "validations" do
    subject(:planning_application_constraints_query) { described_class.new }

    describe "#geojson" do
      it "validates presence" do
        expect { planning_application_constraints_query.valid? }.to change { planning_application_constraints_query.errors[:geojson] }.to ["can't be blank"]
      end
    end

    describe "#wkt" do
      it "validates presence" do
        expect { planning_application_constraints_query.valid? }.to change { planning_application_constraints_query.errors[:wkt] }.to ["can't be blank"]
      end
    end

    describe "#planx_query" do
      it "validates presence" do
        expect { planning_application_constraints_query.valid? }.to change { planning_application_constraints_query.errors[:planx_query] }.to ["can't be blank"]
      end
    end

    describe "#planning_data_query" do
      it "validates presence" do
        expect { planning_application_constraints_query.valid? }.to change { planning_application_constraints_query.errors[:planning_data_query] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { planning_application_constraints_query.valid? }.to change { planning_application_constraints_query.errors[:planning_application] }.to ["must exist"]
      end
    end
  end
end
