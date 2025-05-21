# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Application::CreationService, type: :service do
  describe "#call" do
    let(:local_authority) { create(:local_authority) }
    let!(:application_type_pp) { create(:application_type, :planning_permission) }

    let(:create_planning_application) do
      described_class.new(
        params:, local_authority:
      ).call!
    end

    around do |example|
      travel_to("2023-12-13") do
        example.run
      end
    end

    context "when successfully calling the service with params" do
      let(:planning_application) { PlanningApplication.last }

      context "when application type is planning permission full householder" do
        let(:params) { json_fixture("v2/valid_planning_portal_planning_permission.json").with_indifferent_access }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          expect(planning_application).to have_attributes(
            status: "pending",
            description: "\nDH Test Description",
            payment_reference: nil,
            payment_amount: 0.0,
            agent_first_name: "Jane",
            agent_last_name: "Doe",
            agent_phone: "02071234567",
            agent_email: "example_agent@lambeth.com",
            applicant_first_name: "John",
            applicant_last_name: "Doe",
            applicant_email: "example_applicant@planningportal.com",
            applicant_phone: "070000000",
            local_authority_id: local_authority.id,
            address_1: "2, Brixton Hill",
            town: "London",
            postcode: "SW2 1RW",
            uprn: "100023673934",
            reference: "23-00100-HAPP"
            # lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point("-0.1185926", "51.4656522"),
            # boundary_geojson:  {"coordinates" => [[[[530926, 175216.21], [530897.02, 175205.71], [530896.2343587935, 175191.29044591202], [530904.4400000001, 175189.18999999997], [530912, 175191.28999999998], [530916.06, 175195.62999999998], [530912.9800000001, 175208.50999999998], [530928.8, 175213.83], [530926, 175216.21]]]], "type" => "MultiPolygon"}
            # TO BE UPDATED ONCE LONGLAT transformation implemented from easting / northing to degrees.
          )
        end
      end
    end
  end
end
