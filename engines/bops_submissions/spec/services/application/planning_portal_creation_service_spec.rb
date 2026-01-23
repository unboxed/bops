# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe BopsSubmissions::Application::PlanningPortalCreationService, type: :service do
  describe "#call!" do
    let(:local_authority) { create(:local_authority) }
    let!(:application_type_pp) { create(:application_type, :minor) }

    subject(:create_planning_application) do
      described_class.new(submission: submission).call!
    end

    around do |example|
      travel_to("2023-12-13") { example.run }
    end

    context "when submission.json_file contains valid planning portal JSON" do
      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority: local_authority,
          json_file: json_fixture_submissions("files/applications/PT-10087984.json")
        )
      end

      it "creates a new planning application with expected attributes" do
        expect { create_planning_application }.to change(PlanningApplication, :count).by(1)
        pa = PlanningApplication.last
        expect(pa).to have_attributes(
          status: "not_started",
          description: "\nDH Test Description",
          payment_amount: 0.0,
          payment_reference: nil,
          agent_first_name: "Bob",
          agent_last_name: "Smith",
          agent_phone: "02079260135",
          agent_email: "test@lambeth.gov.uk",
          applicant_first_name: "Bob",
          applicant_last_name: "Smith",
          applicant_email: "test@lambeth.gov.uk",
          applicant_phone: "070000000",
          local_authority_id: local_authority.id,
          address_1: "2, Brixton Hill",
          town: "London",
          postcode: "SW2 1RW",
          uprn: "100023673934",
          reference: "23-00100-MINOR",
          map_east: "530919",
          map_north: "175202",
          latitude: "51.460661",
          longitude: "-0.116898",
          application_type_id: ApplicationType.find_by(code: "pp.full.minor").id
        )
        expect(pa.boundary_geojson["geometry"]).to include("type" => "MultiPolygon")
      end

      it "sets application_type to minor" do
        create_planning_application
        pa = PlanningApplication.last
        expect(pa.application_type.code).to eq("pp.full.minor")
      end
    end

    context "when submission.json_file omits optional fields like feeCalculationSummary or polygon" do
      let(:base_data) { json_fixture_submissions("files/applications/PT-10087984.json") }
      let(:fixture) do
        data = base_data.deep_dup
        data["feeCalculationSummary"] = nil
        data["polygon"] = nil
        data
      end

      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority:,
          json_file: fixture
        )
      end

      it "still creates a planning application, leaving missing values" do
        expect { create_planning_application }.to change(PlanningApplication, :count).by(1)
        pa = PlanningApplication.last

        expect(pa.payment_amount).to eq(0.0)
        expect(pa.payment_reference).to be_nil
        expect(pa.boundary_geojson).to be_nil
      end
    end

    context "when submission.json_file is nil" do
      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority:,
          json_file: nil
        )
      end

      it "raises ArgumentError for missing JSON" do
        expect { create_planning_application }
          .to raise_error(ArgumentError, /has no valid application JSON/)
      end
    end

    context "when submission.json_file is an empty Hash" do
      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority:,
          json_file: {}
        )
      end

      it "raises ArgumentError for missing JSON" do
        expect { create_planning_application }
          .to raise_error(ArgumentError, /has no valid application JSON/)
      end
    end

    context "when submission.json_file is malformed (not matching expected structure)" do
      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority:,
          json_file: {"foo" => "bar"}
        )
      end

      it "raises NoMethodError from parser" do
        expect { create_planning_application }.to raise_error(NoMethodError)
      end
    end

    context "when submission.json_file has applicationData but missing nested keys" do
      let(:submission) do
        create(
          :submission,
          :planning_portal,
          local_authority:,
          json_file: {"applicationData" => {}}
        )
      end

      it "raises NoMethodError from parser" do
        expect { create_planning_application }.to raise_error(NoMethodError)
      end
    end
  end
end
