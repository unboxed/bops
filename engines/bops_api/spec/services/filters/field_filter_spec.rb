# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::FieldFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when the field param is blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params, :description)).to eq(scope)
      end
    end

    context "when filtering by description" do
      let!(:app1) do
        create(:planning_application, local_authority: local_authority, description: "Build a new garage")
      end

      let!(:app2) do
        create(:planning_application, local_authority: local_authority, description: "Extend kitchen")
      end

      let(:params) { {description: "garage"} }

      it "filters using case-insensitive LIKE" do
        result = described_class.call(scope, params, :description)

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "when filtering by postcode" do
      let!(:app1) do
        create(:planning_application, local_authority: local_authority, postcode: "SW1A 1AA")
      end

      let!(:app2) do
        create(:planning_application, local_authority: local_authority, postcode: "E1 6AN")
      end

      let(:params) { {postcode: "SW1A"} }

      it "filters by postcode" do
        result = described_class.call(scope, params, :postcode)

        expect(result).to include(app1)
        expect(result).not_to include(app2)
      end
    end

    context "with custom column name" do
      let!(:app1) do
        create(:planning_application, local_authority: local_authority, description: "Build garage")
      end

      let(:params) { {desc: "garage"} }

      it "uses the specified column name" do
        result = described_class.call(scope, params, :desc, "description")

        expect(result).to include(app1)
      end
    end
  end
end
