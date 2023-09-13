# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationConstraintsQuery do
  describe "validations" do
    subject(:planning_application_constraints_query) { described_class.new }

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

    describe ".coordinate_method_presence" do
      let!(:planning_application) { create(:planning_application) }

      it "validates presence" do
        planning_application_constraints_query = build(:planning_application_constraints_query, planning_application:, wkt: nil, geojson: nil)

        expect do
          planning_application_constraints_query.valid?
        end.to change {
          planning_application_constraints_query.errors[:base]
        }.to ["Select at least one coordinate method"]
      end
    end
  end
end
