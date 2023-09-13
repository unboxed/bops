# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintsCreationService, type: :service do
  describe "#call" do
    let!(:local_authority1) { create(:local_authority) }
    let!(:local_authority2) { create(:local_authority, :southwark) }

    let!(:planning_application) { create(:planning_application, local_authority: local_authority1) }
    let!(:constraints_params) do
      ActionController::Parameters.new(
        {
          "conservation_area" => true,
          "protected_trees" => true,
          "national_park" => true,
          "listed_building" => true
        }
      ).to_unsafe_hash
    end

    let(:create_constraints) do
      described_class.new(
        planning_application:,
        constraints_params:
      ).call
    end

    context "when new constraints are added" do
      it "creates the constraint and planning application constraints for the local authority" do
        expect do
          create_constraints
        end.to change(Constraint, :count).by(4).and change(PlanningApplicationConstraint, :count).by(4)

        expect(Constraint.pluck(:type, :category, :local_authority_id)).to eq(
          [
            ["Conservation Area", "local", local_authority1.id],
            ["Protected Trees", "local", local_authority1.id],
            ["National Park", "local", local_authority1.id],
            ["Listed Building", "local", local_authority1.id]
          ]
        )

        expect(planning_application.planning_application_constraints.length).to eq(4)
        expect(planning_application.constraints.length).to eq(4)
      end
    end

    context "when existing constraints are added" do
      let!(:constraint1) { create(:constraint, type: "conservation area", local_authority: local_authority1) }
      let!(:constraint2) { create(:constraint, type: "Protected trees") }
      let!(:constraint3) { create(:constraint, type: "National Park") }
      # Constraint for another local authority
      let!(:constraint4) { create(:constraint, type: "Listed building", local_authority: local_authority2) }

      it "creates planning application constraints using the existing constraint for the local authority" do
        expect do
          create_constraints
        end.to change(Constraint, :count).by(1).and change(PlanningApplicationConstraint, :count).by(4)

        expect(planning_application.planning_application_constraints.length).to eq(4)
        expect(planning_application.constraints.length).to eq(4)
      end
    end

    context "when existing and new constraints are added" do
      let!(:constraint1) { create(:constraint, type: "conservation area") }
      let!(:constraint2) { create(:constraint, type: "Protected trees") }

      it "creates the non existing constraints and planning application constraints" do
        expect do
          create_constraints
        end.to change(Constraint, :count).by(2).and change(PlanningApplicationConstraint, :count).by(4)

        expect(planning_application.planning_application_constraints.length).to eq(4)
        expect(planning_application.constraints.length).to eq(4)
      end
    end

    context "when constraints are removed" do
      let!(:constraint1) { create(:constraint, type: "conservation area") }
      let!(:constraint2) { create(:constraint, type: "Listed Building") }

      before do
        create_constraints
      end

      it "removes the removed constraints" do
        described_class.new(
          planning_application:,
          constraints_params: {
            "conservation_area" => true,
            "protected_trees" => false,
            "national_park" => false,
            "listed_building" => true
          }
        ).call

        app_constraints = planning_application.planning_application_constraints

        expect(app_constraints.active.count).to eq(2)
        expect(app_constraints.active.map(&:type)).to eq(["conservation area",
                                                          "Listed Building"])
        expect(app_constraints.removed.count).to eq(2)
        expect(app_constraints.removed.map(&:type)).to eq(["Protected Trees",
                                                           "National Park"])
      end
    end

    [ActiveRecord::RecordInvalid, NoMethodError].each do |error|
      context "when there is an error of type: #{error} creating the constraints" do
        before { allow_any_instance_of(Constraint).to receive(:save!).and_raise(error) }

        it "raises an error" do
          expect(Appsignal).to receive(:send_error)

          create_constraints
        end
      end

      context "when there is an error of type: #{error} creating the planning application constraints" do
        before { allow_any_instance_of(PlanningApplicationConstraint).to receive(:save!).and_raise(error) }

        it "raises an error" do
          expect(Appsignal).to receive(:send_error)

          create_constraints
        end
      end
    end
  end
end
