# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::CreationService, type: :service do
  describe "#call" do
    let(:user) { create(:api_user) }
    let!(:application_type_ldc) { create(:application_type) }
    let!(:application_type_pp) { create(:application_type, :planning_permission) }

    context "when successfully calling the service with params" do
      let(:local_authority) { create(:local_authority) }

      let(:create_planning_application) do
        described_class.new(
          local_authority:, user:, params:
        ).call!
      end

      context "when application type is LDCE" do
        let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("v2/valid_lawful_development_certificate_existing.json").read)) }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          planning_application = PlanningApplication.last
          expect(planning_application).to have_attributes(
            status: "pending",
            description: "Construction of a small outbuilding for use as a writing studio.",
            payment_reference: "sandbox-ref-123",
            payment_amount: 0.206e3,
            work_status: "existing",
            agent_first_name: "F",
            agent_last_name: "Fox",
            agent_phone: "0234 567 8910",
            agent_email: "f.fox@boggischickenshed.com",
            applicant_first_name: "Roald",
            applicant_last_name: "Dahl",
            applicant_email: "f.fox@boggischickenshed.com",
            applicant_phone: "Not provided by agent",
            local_authority_id: local_authority.id,
            address_1: ", WHITEFIELD LANE",
            town: "GREAT MISSENDEN",
            postcode: "HP16 0BP",
            uprn: "100081174436",
            result_heading: "Planning permission / Immune",
            result_description: "It looks like the changes may now be beyond the time limit for enforcement action. This does not apply if the changes have been deliberately concealed.",
            api_user_id: user.id,
            parish_name: "Southwark, unparished area",
            reference: "23-00100-LDCE",
            boundary_geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-0.7085376977920632,51.699564621757816],[-0.7086127996444802,51.69965605327502],[-0.708982944488535,51.699654390885456],[-0.7089909911155797,51.699673508361855],[-0.7089319825172521,51.699683482694184],[-0.7089520990848638,51.69973002954916],[-0.7091867923736667,51.69968930105364],[-0.7092216610908603,51.699688469859495],[-0.709239095449457,51.69968514508267],[-0.709253847599039,51.6997134056779],[-0.7093128561973666,51.69970176896433],[-0.7092699408531282,51.699610337539525],[-0.7096253335476013,51.699648572521454],[-0.7098613679409116,51.69958457046823],[-0.7098962366581053,51.69955049141595],[-0.7098090648651213,51.6994216557425],[-0.7099243998527616,51.699390070166544],[-0.7098264992237182,51.699238791576136],[-0.7097460329532714,51.699236297968724],[-0.7095716893673034,51.69927536446852],[-0.7095421850681398,51.69927619567025],[-0.7092954218387698,51.69931941814053],[-0.7090929150581455,51.69937427737031],[-0.709021836519251,51.69938923896689],[-0.7089574635028936,51.6994008757608],[-0.7088904082775213,51.69942082454341],[-0.7086691260337761,51.699501450783515],[-0.7086181640624932,51.699517243535354],[-0.7085457444191079,51.699541348251245],[-0.7085350155830483,51.69954799782576],[-0.7085376977920632,51.699564621757816]]]},\"properties\":null}"
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses].to_json)
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params.to_json,
            session_id: "95f90e21-93f5-4761-90b3-815c673e041f"
          )
        end
      end

      context "when application type is LDCP" do
        let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("v2/valid_lawful_development_certificate_proposed.json").read)) }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          planning_application = PlanningApplication.last
          expect(planning_application).to have_attributes(
            status: "pending",
            description: "Rear extension of a home",
            payment_reference: nil,
            payment_amount: 0.0,
            work_status: "proposed",
            agent_first_name: nil,
            agent_last_name: nil,
            agent_phone: nil,
            agent_email: nil,
            applicant_first_name: "Enid",
            applicant_last_name: "Blyton",
            applicant_email: "famousfive@example.com",
            applicant_phone: "05555 555 555",
            local_authority_id: local_authority.id,
            address_1: "7, BLYTON CLOSE",
            town: "BEACONSFIELD",
            postcode: "HP9 2LX",
            uprn: "100080482163",
            result_heading: "Planning permission / Permitted development",
            result_description: "It looks like the proposed changes may fall within the rules for Permitted Development and therefore would not need planning permission.",
            api_user_id: user.id,
            parish_name: "Southwark, unparished area",
            reference: "23-00100-LDCP",
            boundary_geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-0.646633654832832,51.61556919642334],[-0.6466296315193095,51.61554504700152],[-0.6465049088001171,51.61551173743314],[-0.6464512646198194,51.61522027766699],[-0.6463131308555524,51.61522943785954],[-0.6463037431240002,51.61520695374722],[-0.6462487578391951,51.615222775901515],[-0.6462393701076429,51.61520861923739],[-0.6459456682205124,51.615292726412235],[-0.6460489332675857,51.61561499701554],[-0.646633654832832,51.61556919642334]]]},\"properties\":null}"
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses].to_json)
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params.to_json,
            session_id: "8da51c5b-a2a0-4386-a15d-29d66f9c121c"
          )
        end
      end

      context "when application type is planning permission full householder" do
        let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("v2/valid_planning_permission.json").read)) }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          planning_application = PlanningApplication.last
          expect(planning_application).to have_attributes(
            status: "pending",
            description: "Roof extension to the rear of the property, incorporating starship launchpad.",
            payment_reference: "sandbox-ref-456",
            payment_amount: 0.206e3,
            agent_first_name: "Ziggy",
            agent_last_name: "Stardust",
            agent_phone: "01100 0110 0011",
            agent_email: "ziggy@example.com",
            applicant_first_name: "David",
            applicant_last_name: "Bowie",
            applicant_email: "ziggy@example.com",
            applicant_phone: "Not provided by agent",
            local_authority_id: local_authority.id,
            address_1: "40, STANSFIELD ROAD",
            town: "LONDON",
            postcode: "SW9 9RZ",
            uprn: "100021892955",
            result_heading: nil,
            result_description: nil,
            api_user_id: user.id,
            parish_name: "Southwark, unparished area",
            reference: "23-00100-HAPP",
            boundary_geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-0.1186569035053321,51.465703531871384],[-0.1185938715934822,51.465724418998775],[-0.1184195280075143,51.46552473766957],[-0.11848390102387167,51.4655038504508],[-0.1186569035053321,51.465703531871384]]]},\"properties\":null}"
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses].to_json)
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params.to_json,
            session_id: "81bcaa0f-baf5-4573-ba0a-ea868c573faf"
          )
        end
      end

      context "when submission is not valid against the schema specification" do
        let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("v1/valid_planning_permission.json").read)) }

        it "raises an error" do
          expect { create_planning_application }.to raise_error(
            BopsApi::Errors::InvalidSchemaError, "We couldn’t process your request because some information is missing or incorrect."
          )
        end
      end

      context "when application type is not supported" do
        let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("v2/valid_prior_approval.json").read)) }

        it "raises a not found error" do
          expect { create_planning_application }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when environment is production" do
        let(:params) { {} }

        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")
        end

        it "raises an error" do
          expect { create_planning_application }.to raise_error(
            BopsApi::Errors::NotPermittedError, "Creating planning applications using this endpoint is not permitted in production"
          )
        end
      end
    end
  end
end
