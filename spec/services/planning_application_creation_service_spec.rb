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

      context "when application might be immune" do
        let(:planning_application) { create(:planning_application, :from_planx_immunity, api_user:) }

        it "queues the job to create immunity details" do
          planning_application = PlanningApplication.last

          expect do
            described_class.new(
              planning_application:
            ).call
          end.to change(ImmunityDetail, :count).by(1)
            .and change(EvidenceGroup, :count).by(2)
        end
      end

      context "when application is applying for prior approval" do
        let(:planning_application) { create(:planning_application, :from_planx_prior_approval, api_user:) }

        context "when we accept that type of prior approval" do
          it "is successful" do
            planning_application = PlanningApplication.last

            expect do
              described_class.new(
                planning_application:
              ).call
            end.to change(PlanningApplication, :count).by(1)
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
            expect { create_planning_application }.to raise_error(described_class::CreateError, "BOPS does not accept this Prior Approval type")
          end
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

        it "creates new documents" do
          expect { create_planning_application }.to change(Document, :count).by(1)
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
