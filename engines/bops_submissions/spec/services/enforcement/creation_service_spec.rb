# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe BopsSubmissions::Enforcement::CreationService, type: :service do
  describe "#call!" do
    let(:local_authority) { create(:local_authority) }
    let(:submission) do
      create(
        :submission,
        local_authority: local_authority,
        request_body: json_fixture_api("v0.7.5/enforcement/breach.json")
      )
    end
    let(:service) { described_class.new(submission: submission) }
    let!(:application_type_enforcement) { create(:application_type, :enforcement) }
    let(:parsed_enforcement_data) do
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      {
        description: "Unauthorised erection of a library in the front garden",
        address_1: "CHARES DICKENS WRITING CHALET–EASTGATE HOUSE–HIGH STREET",
        address_2: nil,
        town: "ROCHESTER",
        county: nil,
        postcode: "ME1 1EW",
        uprn: "000044009430",
        boundary_geojson: nil,
        lonlat: factory.point(0.506217, 51.3873264),
        proposal_details: submission.request_body["responses"]
      }
    end

    it "creates a CaseRecord delegating to the new Enforcement" do
      enforcement = service.call!

      case_record = submission.reload.case_record
      expect(case_record).to have_attributes(
        caseable: enforcement,
        local_authority: local_authority
      )

      expect(enforcement).to have_attributes(
        **parsed_enforcement_data,
        application_type: application_type_enforcement
      )
    end

    context "when saving Enforcement fails" do
      before do
        allow_any_instance_of(Enforcement).to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new(Enforcement.new))
      end

      it "rolls back the transaction" do
        expect {
          begin
            service.call!
          rescue
            ActiveRecord::RecordInvalid
          end
        }.not_to change(Enforcement, :count)

        expect(submission.reload.case_record).to be_nil
      end
    end
  end
end
