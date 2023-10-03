# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintsCreationService, type: :service do
  describe "#call" do
    let!(:api_user) { create(:api_user, name: "PlanX") }
    let!(:local_authority1) { create(:local_authority) }
    let!(:local_authority2) { create(:local_authority, :southwark) }

    let!(:planning_application) { create(:planning_application, :with_boundary_geojson, local_authority: local_authority1, api_user:) }
    let(:constraints_params) { JSON.parse(file_fixture("planx_constraints_proposed_params.json").read) }

    let(:create_constraints) do
      described_class.new(
        planning_application:,
        constraints_params:
      ).call
    end

    context "when existing constraints are added" do
      let!(:constraint1) { create(:constraint, local_authority: local_authority1) }
      let!(:constraint2) { create(:constraint, :tpo) }
      let!(:constraint3) { create(:constraint, :national_park) }
      # Constraint for another local authority
      let!(:constraint4) { create(:constraint, :listed, local_authority: local_authority2) }

      it "creates planning application constraints using the existing constraint for the local authority" do
        expect(Constraint.count).to eq(4)

        expect do
          create_constraints
        end.to change(PlanningApplicationConstraint, :count).by(3)

        expect(planning_application.planning_application_constraints.length).to eq(3)
        expect(planning_application.constraints.length).to eq(3)
      end
    end

    context "when existing and new constraints are added" do
      let!(:constraint1) { create(:constraint) }
      let!(:constraint2) { create(:constraint, :tpo) }

      it "creates the non existing constraints and planning application constraints" do
        expect(Appsignal).to receive(:send_error).with("Unexpected constraint type: listed, category Heritage and conservation")
        expect(Appsignal).to receive(:send_error).with("Unexpected constraint type: designated, category ")

        expect do
          create_constraints
        end.to change(PlanningApplicationConstraint, :count).by(2)

        expect(planning_application.planning_application_constraints.length).to eq(2)
        expect(planning_application.constraints.length).to eq(2)
      end
    end

    [ActiveRecord::RecordInvalid, NoMethodError].each do |error|
      context "when there is an error of type: #{error} creating the planning application constraints" do
        let(:planning_application_constraints) { double }

        before do
          allow(planning_application_constraints).to receive(:create!).and_raise(error)
          allow(planning_application_constraints).to receive(:active).and_return([])
        end

        it "raises an error" do
          expect(Appsignal).to receive(:send_error).exactly(4).times

          create_constraints
        end
      end
    end
  end
end
