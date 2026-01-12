# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintsCreationService, type: :service do
  describe "#call" do
    let!(:api_user) { create(:api_user, :planx) }
    let!(:local_authority1) { create(:local_authority) }
    let!(:local_authority2) { create(:local_authority, :southwark) }

    let!(:planning_application) { create(:planning_application, :with_boundary_geojson, local_authority: local_authority1, api_user:) }
    let!(:constraints_params) { JSON.parse(file_fixture("planx_constraints_proposed_params.json").read) }

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
        expect(Appsignal).to receive(:report_error).with("Unexpected constraint type: listed, category Heritage and conservation")
        expect(Appsignal).to receive(:report_error).with("Unexpected constraint type: designated, category ")

        expect do
          create_constraints
        end.to change(PlanningApplicationConstraint, :count).by(2)

        expect(planning_application.planning_application_constraints.length).to eq(2)
        expect(planning_application.constraints.length).to eq(2)
      end
    end

    context "when existing constraints are missing and new constraints are added" do
      let!(:designated_constraint) { create(:constraint, :designated) }
      let!(:conservation_area_constraint) { create(:constraint, :conservation_area) }
      let!(:listed_constraint) { create(:constraint, :listed) }
      let!(:national_park_constraint) { create(:constraint, :national_park) }
      let!(:road_classified_constraint) { create(:constraint, :road_classified) }
      let!(:tpo_constraint) { create(:constraint, :tpo) }

      before do
        planning_application.planning_application_constraints.create! do |c|
          c.constraint = designated_constraint
          c.identified_by = api_user.name
        end

        planning_application.planning_application_constraints.create! do |c|
          c.constraint = national_park_constraint
          c.identified_by = api_user.name
        end

        planning_application.planning_application_constraints.create! do |c|
          c.constraint = road_classified_constraint
          c.identified_by = api_user.name
        end
      end

      it "creates new constraints and removes old constraints" do
        expect {
          create_constraints
        }.to change {
          planning_application.planning_application_constraints.reload.map(&:type)
        }.from(
          an_array_matching(%w[
            designated
            designated_nationalpark
            road_classified
          ])
        ).to(
          an_array_matching(%w[
            designated
            designated_conservationarea
            listed
            tpo
          ])
        )
      end
    end

    context "when existing constraints includes an ignored constraint" do
      let!(:designated_constraint) { create(:constraint, :designated) }
      let!(:conservation_area_constraint) { create(:constraint, :conservation_area) }
      let!(:listed_constraint) { create(:constraint, :listed) }
      let!(:road_classified_constraint) { create(:constraint, :road_classified) }
      let!(:tpo_constraint) { create(:constraint, :tpo) }

      let!(:constraints_params) { JSON.parse(file_fixture("planx_constraints_proposed_params.json").read).first }

      before do
        planning_application.planning_application_constraints.create! do |c|
          c.constraint = road_classified_constraint
          c.identified_by = api_user.name
        end
      end

      it "doesn't remove the ignored constraint" do
        expect {
          create_constraints
        }.to change {
          planning_application.planning_application_constraints.reload.map(&:type)
        }.from(
          an_array_matching(%w[
            road_classified
          ])
        ).to(
          an_array_matching(%w[
            designated
            designated_conservationarea
            listed
            road_classified
            tpo
          ])
        )
      end
    end

    context "when the planning application was created from within BOPS" do
      let!(:api_user) { nil }
      let!(:constraint1) { create(:constraint, local_authority: local_authority1) }

      subject { planning_application.planning_application_constraints.first }

      it "sets the constraint identified_by to BOPS" do
        expect do
          create_constraints
        end.to change(PlanningApplicationConstraint, :count).by(1)

        expect(subject.identified_by).to eq("BOPS")
      end
    end

    context "when there is an error creating a planning application constraint" do
      let!(:designated_constraint) { create(:constraint, :designated) }
      let!(:conservation_area_constraint) { create(:constraint, :conservation_area) }
      let!(:listed_constraint) { create(:constraint, :listed) }
      let!(:tpo_constraint) { create(:constraint, :tpo) }

      let(:planning_application_constraints) { planning_application.planning_application_constraints }
      let(:error) { ActiveRecord::RecordInvalid }

      before do
        allow(planning_application_constraints).to receive(:create!).and_raise(error)
      end

      it "captures the error and reports it to Appsignal" do
        expect(Appsignal).to receive(:report_error).with(an_instance_of(error))

        create_constraints
      end
    end

    context "when there is an error updating a planning application constraint" do
      let!(:designated_constraint) { create(:constraint, :designated) }
      let!(:conservation_area_constraint) { create(:constraint, :conservation_area) }
      let!(:listed_constraint) { create(:constraint, :listed) }
      let!(:tpo_constraint) { create(:constraint, :tpo) }

      let(:planning_application_constraints) { planning_application.planning_application_constraints }
      let(:error) { ActiveRecord::RecordNotSaved }

      before do
        planning_application.planning_application_constraints.create! do |c|
          c.constraint = designated_constraint
          c.identified_by = api_user.name
        end

        allow_any_instance_of(PlanningApplicationConstraint).to receive(:update!).and_raise(error)
      end

      it "captures the error and reports it to Appsignal" do
        expect(Appsignal).to receive(:report_error).with(an_instance_of(error))

        create_constraints
      end
    end

    context "when there is an error destroying a planning application constraint" do
      let!(:designated_constraint) { create(:constraint, :designated) }
      let!(:conservation_area_constraint) { create(:constraint, :conservation_area) }
      let!(:listed_constraint) { create(:constraint, :listed) }
      let!(:national_park_constraint) { create(:constraint, :national_park) }
      let!(:tpo_constraint) { create(:constraint, :tpo) }

      let(:planning_application_constraints) { planning_application.planning_application_constraints }
      let(:error) { ActiveRecord::RecordNotSaved }

      before do
        planning_application.planning_application_constraints.create! do |c|
          c.constraint = national_park_constraint
          c.identified_by = api_user.name
        end

        allow_any_instance_of(PlanningApplicationConstraint).to receive(:destroy!).and_raise(error)
      end

      it "captures the error and reports it to Appsignal" do
        expect(Appsignal).to receive(:report_error).with(an_instance_of(error))

        create_constraints
      end
    end
  end
end
