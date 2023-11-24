# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationCreationService, type: :service do
  describe "#call" do
    let(:api_user) { create(:api_user) }
    let!(:application_type_pa) { create(:application_type, :prior_approval) }
    let!(:application_type_ldc) { create(:application_type) }

    before do
      stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(
          status: 200,
          body: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").read,
          headers: {"Content-Type" => "application/pdf"}
        )
    end

    context "when a planning application is provided" do
      let!(:planning_application) { create(:planning_application, :from_planx, api_user:) }

      let(:create_planning_application) do
        described_class.new(
          planning_application:
        ).call
      end

      before do
        allow_any_instance_of(PlanningApplication).to receive(:can_clone?).and_return(true)
      end

      context "when successful" do
        before do
          # Create the planning application to be cloned using the params_v1 value from planx params
          described_class.new(
            planning_application:
          ).call
        end

        it "creates a new planning application identical to how it came via planx using the params_v1 value as the params" do
          planning_application = PlanningApplication.last

          expect(PlanningApplicationAnonymisationService).not_to receive(:new)

          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(PlanningApplication, :count).by(1)

          cloned_planning_application = PlanningApplication.last

          expect(planning_application.reference).not_to eq(cloned_planning_application.reference)

          expect(cloned_planning_application).to have_attributes(
            id: planning_application.id + 1,
            local_authority_id: planning_application.local_authority.id,
            api_user_id: planning_application.api_user.id,
            address_1: planning_application.address_1,
            address_2: planning_application.address_2,
            town: planning_application.town,
            county: planning_application.county,
            postcode: planning_application.postcode,
            uprn: planning_application.uprn,
            boundary_geojson: planning_application.boundary_geojson,
            agent_first_name: planning_application.agent_first_name,
            agent_email: planning_application.agent_email,
            applicant_email: planning_application.applicant_email,
            result_flag: planning_application.result_flag,
            description: planning_application.description,
            from_production: false,
            lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point(planning_application.longitude, planning_application.latitude)
          )

          expect(planning_application.params_v1).to eq(cloned_planning_application.params_v1)
          expect(cloned_planning_application.planx_planning_data.session_id).to eq(nil)

          # Proposal details have their own object id i.e. ProposalDetail:0x00007fe42a8476a8 so compare the json value instead
          proposal_details = planning_application.proposal_details.map(&:to_json)
          cloned_proposal_details = cloned_planning_application.proposal_details.map(&:to_json)
          expect(proposal_details).to eq(cloned_proposal_details)

          expect(ImmunityDetail.count).to eq 0
        end
      end

      context "when application might be immune" do
        let(:planning_application) { create(:planning_application, :from_planx_immunity, api_user:) }

        before do
          allow_any_instance_of(PlanningApplication).to receive(:can_clone?).and_return(true)
        end

        it "queues the job to create immunity details" do
          planning_application = PlanningApplication.last

          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(ImmunityDetail, :count).by(1)
        end
      end

      context "when application is applying for prior approval" do
        let(:planning_application) { create(:planning_application, :from_planx_prior_approval, api_user:) }

        before do
          allow_any_instance_of(PlanningApplication).to receive(:can_clone?).and_return(true)
        end

        context "when we accept that type of prior approval" do
          it "is successful" do
            planning_application = PlanningApplication.last

            expect do
              described_class.new(
                planning_application:
              ).call
            end.to change(PlanningApplication, :count).by(1)

            cloned_planning_application = PlanningApplication.last

            expect(planning_application.reference).not_to eq(cloned_planning_application.reference)

            expect(cloned_planning_application.application_type.name).to eq("prior_approval")
          end
        end

        context "when we don't accept that type of prior approval" do
          let!(:planning_application) { create(:planning_application, :from_planx_prior_approval_not_accepted, api_user:) }

          let(:create_planning_application) do
            described_class.new(
              planning_application:
            ).call
          end

          it "raises an error" do
            expect { create_planning_application }.to raise_error(described_class::CreateError, "BoPS does not accept this Prior Approval type")
          end
        end
      end

      context "when can_clone? is false" do
        before { allow(planning_application).to receive(:can_clone?).and_return(false) }

        it "raises an error" do
          expect { create_planning_application }.to raise_error(described_class::CreateError, "Cloning is not permitted in production")
        end
      end

      context "when planning application was not created via PlanX i.e. there is no params_v1 value" do
        let(:planning_application) { create(:planning_application) }

        it "raises an error" do
          expect { create_planning_application }.to raise_error(described_class::CreateError, "Planning application can not be cloned as it was not created via PlanX")
        end
      end

      [Api::V1::Errors::WrongFileTypeError, Api::V1::Errors::GetFileError, ActiveRecord::RecordInvalid, ArgumentError, NoMethodError, ActiveRecord::RecordNotUnique].each do |error|
        context "when there is an error of type: #{error} saving the new planning application" do
          before { allow_any_instance_of(PlanningApplication).to receive(:save!).and_raise(error) }

          it "raises an error" do
            expect { create_planning_application }.to raise_error(described_class::CreateError)
          end
        end
      end
    end

    context "when no planning application is provided" do
      let(:local_authority) { create(:local_authority) }
      let!(:constraint1) { create(:constraint) }
      let!(:constraint2) { create(:constraint, :listed) }
      let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("planx_params.json").read)) }

      let(:create_planning_application) do
        described_class.new(
          local_authority:, params:, api_user:
        ).call
      end

      context "when successful" do
        it "creates a new planning application from the params" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)
        end

        it "calls the constraints creation service" do
          expect { create_planning_application }.to change(PlanningApplicationConstraint, :count).by(2)
        end

        it "creates a new planx planning data record" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)
        end

        it "sets the session_id on the planx planning data record" do
          create_planning_application

          expect(PlanxPlanningData.last.session_id).to eq("21161b70-0e29-40e6-9a38-c42f61f25ab9")
        end
      end
    end

    context "when application type is Householder Application for Planning Permission" do
      let(:local_authority) { create(:local_authority) }
      let(:params) { ActionController::Parameters.new(JSON.parse(file_fixture("planx_params_householder_application_for_planning_permission.json").read)) }
      let!(:application_type) { create(:application_type, :planning_permission) }

      let(:create_planning_application) do
        described_class.new(
          local_authority:, params:, api_user:
        ).call
      end

      context "when successful" do
        it "creates a new planning application from the params" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          planning_application = PlanningApplication.last
          expect(planning_application.reference).to eq("#{planning_application.created_at.year % 100}-00100-HAPP")
        end
      end
    end
  end
end
