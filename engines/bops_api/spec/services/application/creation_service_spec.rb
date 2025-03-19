# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::CreationService, type: :service do
  describe "#call" do
    let(:user) { create(:api_user) }
    let(:local_authority) { create(:local_authority) }
    let!(:application_type_ldce) { create(:application_type, :ldc_existing) }
    let!(:application_type_ldcp) { create(:application_type, :ldc_proposed) }
    let!(:application_type_pp) { create(:application_type, :planning_permission) }
    let!(:application_type_preapp) { create(:application_type, :pre_application) }

    let!(:article4_constraint) { create(:constraint, type: "article4", category: "general_policy") }
    let!(:designated_constraint) { create(:constraint, type: "designated", category: "heritage_and_conservation") }
    let!(:designated_aonb_constraint) { create(:constraint, type: "designated_aonb", category: "heritage_and_conservation") }

    let(:create_planning_application) do
      described_class.new(
        user:, params:, local_authority:
      ).call!
    end

    around do |example|
      travel_to("2023-12-13") do
        example.run
      end
    end

    before do
      [
        ["Elevations.pdf", "planx/Elevations.pdf", "application/pdf"],
        ["Plan.pdf", "planx/Plan.pdf", "application/pdf"],
        ["Roald-Dahl-letter-one-use.pdf", "planx/Roald-Dahl-letter-one-use.pdf", "application/pdf"],
        ["RoaldDahlHut.jpg", "planx/RoaldDahlHut.jpg", "image/jpeg"],
        ["RoofPlan.pdf", "planx/RoofPlan.pdf", "application/pdf"],
        ["Site%20plan.pdf", "planx/Site plan.pdf", "application/pdf"],
        ["Test%20document.pdf", "planx/Test document.pdf", "application/pdf"],
        ["correspondence.pdf", "planx/Test document.pdf", "application/pdf"],
        ["myPlans.pdf", "planx/Plan.pdf", "application/pdf"]
      ].each do |file, fixture, content_type|
        stub_request(:get, %r{\Ahttps://api.editor.planx.dev/file/private/\w+/#{Regexp.escape(file)}\z})
          .with(headers: {"Api-Key" => "G41sAys9uPMUVBH5WUKsYE4H"})
          .to_return(
            status: 200,
            body: file_fixture(fixture).read,
            headers: {"Content-Type" => content_type}
          )
      end
      Rails.configuration.os_vector_tiles_api_key = "testtest"
      stub_os_places_api_request_for_radius(51.4656522, -0.1185926)
    end

    context "when successfully calling the service with params" do
      let(:planning_application) { PlanningApplication.last }
      let(:documents) { planning_application.documents }
      let(:planning_application_constraints) { planning_application.planning_application_constraints }

      context "when application type is LDCE" do
        let(:params) { json_fixture("v2/valid_ldce_with_council_tax_document.json").with_indifferent_access }

        before do
          stub_planning_data_entity_request("1000005")
          stub_planning_data_entity_request("7010002192")
        end

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)
          expect(BopsApi::PostApplicationToStagingJob).not_to have_been_enqueued

          expect(planning_application).to have_attributes(
            status: "pending",
            description: "Construction of a small outbuilding for use as a writing studio.",
            payment_reference: "sandbox-ref-123",
            payment_amount: 0.206e3,
            agent_first_name: "F",
            agent_last_name: "Fox",
            agent_phone: "0234 567 8910",
            agent_email: "f.fox@boggischickenshed.com",
            applicant_first_name: "Roald",
            applicant_last_name: "Dahl",
            applicant_email: "f.fox@boggischickenshed.com",
            applicant_phone: "Not provided by agent",
            local_authority_id: local_authority.id,
            address_1: "GIPSY HOUSE, WHITEFIELD LANE",
            town: "GREAT MISSENDEN",
            postcode: "HP16 0BP",
            uprn: "100081174436",
            result_heading: "Planning permission / Immune",
            result_description: "It looks like the changes may now be beyond the time limit for enforcement action. This does not apply if the changes have been deliberately concealed.",
            api_user_id: user.id,
            parish_name: "Southwark, unparished area",
            reference: "23-00100-LDCE",
            lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point("-0.708966", "51.6994957"),
            boundary_geojson: {"type" => "Feature", "geometry" => {"coordinates" => [[[-0.7085376977920632, 51.699564621757816], [-0.7086127996444802, 51.69965605327502], [-0.708982944488535, 51.699654390885456], [-0.7089909911155797, 51.699673508361855], [-0.7089319825172521, 51.699683482694184], [-0.7089520990848638, 51.69973002954916], [-0.7091867923736667, 51.69968930105364], [-0.7092216610908603, 51.699688469859495], [-0.709239095449457, 51.69968514508267], [-0.709253847599039, 51.6997134056779], [-0.7093128561973666, 51.69970176896433], [-0.7092699408531282, 51.699610337539525], [-0.7096253335476013, 51.699648572521454], [-0.7098613679409116, 51.69958457046823], [-0.7098962366581053, 51.69955049141595], [-0.7098090648651213, 51.6994216557425], [-0.7099243998527616, 51.699390070166544], [-0.7098264992237182, 51.699238791576136], [-0.7097460329532714, 51.699236297968724], [-0.7095716893673034, 51.69927536446852], [-0.7095421850681398, 51.69927619567025], [-0.7092954218387698, 51.69931941814053], [-0.7090929150581455, 51.69937427737031], [-0.709021836519251, 51.69938923896689], [-0.7089574635028936, 51.6994008757608], [-0.7088904082775213, 51.69942082454341], [-0.7086691260337761, 51.699501450783515], [-0.7086181640624932, 51.699517243535354], [-0.7085457444191079, 51.699541348251245], [-0.7085350155830483, 51.69954799782576], [-0.7085376977920632, 51.699564621757816]]], "type" => "Polygon"}, "properties" => nil}
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses])
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params,
            session_id: "95f90e21-93f5-4761-90b3-815c673e041f"
          )
        end

        it "uploads the documents" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(Document, :count).by(7)

          expect(documents).to include(
            an_object_having_attributes(
              name: "RoaldDahlHut.jpg",
              tags: %w[photographs.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Site plan.pdf",
              tags: %w[sitePlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Elevations.pdf",
              tags: %w[elevations.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Plan.pdf",
              tags: %w[floorPlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Roald-Dahl-letter-one-use.pdf",
              tags: %w[otherEvidence],
              applicant_description: "Nothing really, this is just a test. "
            ),
            an_object_having_attributes(
              name: "Test document.pdf",
              tags: %w[constructionInvoice],
              applicant_description: "Nothing, it's a test document. "
            ),
            an_object_having_attributes(
              name: "Test document.pdf",
              tags: %w[councilTaxBill],
              applicant_description: "Council tax bill"
            )
          )
        end

        it "creates the ownership certificate information" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(OwnershipCertificate, :count).by(1)
          expect(OwnershipCertificate.last.land_owners.length).to eq 1

          expect(OwnershipCertificate.last).to have_attributes(
            certificate_type: "b",
            planning_application_id: PlanningApplication.last.id
          )

          expect(LandOwner.last).to have_attributes(
            ownership_certificate_id: OwnershipCertificate.last.id,
            name: "Matilda Wormwood",
            town: "Reading",
            county: "",
            country: "",
            address_1: "9, Library Way",
            address_2: "",
            postcode: "L1T3R8Y",
            notice_given: true,
            notice_given_at: Time.zone.parse("1988-04-01 00:00")
          )
        end

        it "creates the expected constraints" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(PlanningApplicationConstraint, :count).by(3)

          expect(planning_application_constraints).to match_array([
            an_object_having_attributes(
              constraint_id: article4_constraint.id,
              data: [
                a_hash_including("name" => "Whole District excluding the Town of Chesham - Poultry production.")
              ],
              metadata: {"description" => "Article 4 Direction area"},
              identified: true,
              identified_by: "PlanX"
            ),
            an_object_having_attributes(
              constraint_id: designated_constraint.id,
              data: [],
              metadata: {"description" => "Designated land"},
              identified: true,
              identified_by: "PlanX"
            ),
            an_object_having_attributes(
              constraint_id: designated_aonb_constraint.id,
              data: [
                a_hash_including("name" => "Chilterns")
              ],
              metadata: {"description" => "Area of Outstanding Natural Beauty (AONB)"},
              identified: true,
              identified_by: "PlanX"
            )
          ])
        end
      end

      context "when application type is LDCP" do
        let(:params) { json_fixture("v2/valid_lawful_development_certificate_proposed.json").with_indifferent_access }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

          expect(planning_application).to have_attributes(
            status: "pending",
            description: "Rear extension of a home",
            payment_reference: nil,
            payment_amount: 0.0,
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
            lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point("-0.6463271", "51.6154458"),
            boundary_geojson: {"type" => "Feature", "geometry" => {"type" => "Polygon", "coordinates" => [[[-0.646633654832832, 51.61556919642334], [-0.6466296315193095, 51.61554504700152], [-0.6465049088001171, 51.61551173743314], [-0.6464512646198194, 51.61522027766699], [-0.6463131308555524, 51.61522943785954], [-0.6463037431240002, 51.61520695374722], [-0.6462487578391951, 51.615222775901515], [-0.6462393701076429, 51.61520861923739], [-0.6459456682205124, 51.615292726412235], [-0.6460489332675857, 51.61561499701554], [-0.646633654832832, 51.61556919642334]]]}, "properties" => nil}
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses])
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params,
            session_id: "8da51c5b-a2a0-4386-a15d-29d66f9c121c"
          )
        end

        it "uploads the documents" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(Document, :count).by(8)

          expect(documents).to include(
            an_object_having_attributes(
              name: "RoofPlan.pdf",
              tags: %w[roofPlan.existing],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Site plan.pdf",
              tags: %w[sitePlan.existing],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "RoofPlan.pdf",
              tags: %w[roofPlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Site plan.pdf",
              tags: %w[sitePlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Elevations.pdf",
              tags: %w[elevations.existing],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Plan.pdf",
              tags: %w[floorPlan.existing],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Elevations.pdf",
              tags: %w[elevations.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Plan.pdf",
              tags: %w[floorPlan.proposed],
              applicant_description: nil
            )
          )
        end

        it "creates the ownership certificate information" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(OwnershipCertificate, :count).by(1)
          expect(OwnershipCertificate.last.land_owners.length).to eq 0

          expect(OwnershipCertificate.last).to have_attributes(
            certificate_type: "a",
            planning_application_id: PlanningApplication.last.id
          )
        end

        it "doesn't create any constraints" do
          expect { create_planning_application }.not_to change(PlanningApplicationConstraint, :count)
        end
      end

      context "when application type is planning permission full householder" do
        let(:params) { json_fixture("v2/valid_planning_permission.json").with_indifferent_access }

        it "creates a new planning application with expected attributes" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)

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
            lonlat: RGeo::Geographic.spherical_factory(srid: 4326).point("-0.1185926", "51.4656522"),
            boundary_geojson: {"geometry" => {"coordinates" => [[[-0.1186569035053321, 51.465703531871384], [-0.1185938715934822, 51.465724418998775], [-0.1184195280075143, 51.46552473766957], [-0.11848390102387167, 51.4655038504508], [-0.1186569035053321, 51.465703531871384]]], "type" => "Polygon"}, "properties" => nil, "type" => "Feature"}
          )

          expect(planning_application.read_attribute(:proposal_details)).to eq(params[:responses])
        end

        it "creates a new planx planning data record with expected attributes" do
          expect { create_planning_application }.to change(PlanxPlanningData, :count).by(1)

          expect(PlanxPlanningData.last).to have_attributes(
            params_v2: params,
            session_id: "81bcaa0f-baf5-4573-ba0a-ea868c573faf"
          )
        end

        it "uploads the documents" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(Document, :count).by(4)

          expect(documents).to include(
            an_object_having_attributes(
              name: "RoofPlan.pdf",
              tags: %w[roofPlan.existing roofPlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Site plan.pdf",
              tags: %w[sitePlan.existing sitePlan.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Elevations.pdf",
              tags: %w[elevations.existing elevations.proposed],
              applicant_description: nil
            ),
            an_object_having_attributes(
              name: "Plan.pdf",
              tags: %w[floorPlan.existing floorPlan.proposed],
              applicant_description: nil
            )
          )
        end

        it "creates the document checklist" do
          expect {
            create_planning_application
            perform_enqueued_jobs
          }.to change(DocumentChecklist, :count).by(1)
          expect(DocumentChecklist.last.document_checklist_items.length).to eq 8

          expect(DocumentChecklist.last).to have_attributes(
            planning_application_id: PlanningApplication.last.id
          )

          expect(DocumentChecklist.last.document_checklist_items).to include(
            an_object_having_attributes(
              category: "required",
              tags: "roofPlan.existing",
              description: "Roof plan - existing"
            ),
            an_object_having_attributes(
              category: "required",
              tags: "roofPlan.proposed",
              description: "Roof plan - proposed"
            ),
            an_object_having_attributes(
              category: "required",
              tags: "sitePlan.existing",
              description: "Site plan - existing"
            ),
            an_object_having_attributes(
              category: "required",
              tags: "sitePlan.proposed",
              description: "Site plan - proposed"
            ),
            an_object_having_attributes(
              category: "required",
              tags: "elevations.existing",
              description: "Elevations - existing"
            ),
            an_object_having_attributes(
              category: "required",
              tags: "elevations.proposed",
              description: "Elevations - proposed"
            ),
            an_object_having_attributes(
              category: "recommended",
              tags: "floorPlan.existing",
              description: "Floor plan - existing"
            ),
            an_object_having_attributes(
              category: "recommended",
              tags: "floorPlan.proposed",
              description: "Floor plan - proposed"
            )
          )
        end

        it "doesn't create any constraints" do
          expect { create_planning_application }.not_to change(PlanningApplicationConstraint, :count)
        end

        it "creates neighbour boundary geojson" do
          create_planning_application
          perform_enqueued_jobs
          expect(PlanningApplication.last.neighbour_boundary_geojson).not_to be nil
        end
      end

      context "when application type is not supported" do
        let(:params) { json_fixture("v2/valid_prior_approval.json").with_indifferent_access }

        it "raises a not found error" do
          expect { create_planning_application }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when application may be immune" do
        let(:params) { json_fixture("v2/valid_ldce_with_council_tax_document.json").with_indifferent_access }
        let(:service) { described_class.new(local_authority:, user:, params:) }

        before do
          stub_planning_data_entity_request("1000005")
          stub_planning_data_entity_request("7010002192")
        end

        it "creates the immunity details for the planning application" do
          planning_application = nil

          expect do
            planning_application = service.call!
            perform_enqueued_jobs
          end.to change(ImmunityDetail, :count).by(1)

          immunity_detail = ImmunityDetail.last

          expect(immunity_detail).to have_attributes(
            planning_application_id: planning_application.id,
            end_date: "1959-01-01".to_date
          )

          expect(EvidenceGroup.count).to eq 4
        end

        it "creates the evidence groups for the planning application" do
          planning_application = nil

          expect do
            planning_application = service.call!
            perform_enqueued_jobs
          end.to change(EvidenceGroup, :count).by(4)

          council_tax_bill = planning_application.immunity_detail.evidence_groups.where(tag: "councilTaxBill").first

          expect(council_tax_bill).to have_attributes(
            immunity_detail_id: planning_application.immunity_detail.id,
            start_date: "2013-03-02".to_date,
            end_date: "2019-04-01".to_date,
            applicant_comment: "That I was paying council tax"
          )

          other_document = planning_application.immunity_detail.evidence_groups.where(tag: "otherEvidence").first

          expect(other_document).to have_attributes(
            immunity_detail_id: planning_application.immunity_detail.id,
            start_date: nil,
            end_date: nil,
            applicant_comment: "Nothing really, this is just a test. "
          )
        end
      end

      context "when application property has history" do
        let(:local_authority) { create(:local_authority, planning_history_enabled: true) }
        let(:params) { json_fixture("v2/valid_planning_permission.json").with_indifferent_access }

        before do
          stub_paapi_api_request_for("100021892955").to_return(paapi_api_response(:ok, "100021892955"))
        end

        it "creates a new planning application with the expected site history" do
          expect { create_planning_application }.to change(PlanningApplication, :count).by(1)
          expect { perform_enqueued_jobs }.to change(SiteHistory, :count).by(1)

          expect(planning_application.site_histories).to match_array([
            an_object_having_attributes(
              date: "2022-09-16".to_date,
              reference: "22/06601/FUL",
              description: "Householder application for construction of detached two storey double garage with external staircase",
              decision: "Application Refused"
            )
          ])
        end
      end

      context "when application type is preApp" do
        let(:params) { json_fixture("v2/preApplication.json").with_indifferent_access }
        let(:planning_application) { create_planning_application }
        let(:service) { described_class.new(local_authority:, user:, params:, planning_application:) }

        it "creates a planning application with pre-application services" do
          service.call!
          perform_enqueued_jobs
          expect(planning_application.additional_services).to be_present
        end
      end

      context "when in production environment" do
        let(:params) { json_fixture("v2/valid_planning_permission.json").with_indifferent_access }

        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")
          params[:metadata][:source] = "BOPS production"
          Rails.configuration.planx_file_production_api_key = "G41sAys9uPMUVBH5WUKsYE4H"
        end

        it "calls the post application to staging job" do
          create_planning_application

          expect(BopsApi::PostApplicationToStagingJob).to have_been_enqueued
        end

        it "calls the anonymisation service" do
          expect(BopsApi::Application::AnonymisationService).to receive(:new).and_call_original
          expect(BopsApi::Application::DocumentsService).to receive(:new).and_call_original

          create_planning_application
          perform_enqueued_jobs
        end
      end
    end
  end
end
