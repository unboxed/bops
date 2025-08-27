# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe BopsSubmissions::Enforcement::CreationService, type: :service do
  describe "#call!" do
    let(:local_authority) { create(:local_authority) }
    let(:submission) do
      create(
        :submission,
        local_authority: local_authority,
        request_body: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
      )
    end
    let(:service) { described_class.new(submission: submission) }
    let!(:expected_proposal_details) do
      submission.request_body["responses"]
    end
    let(:factory) { RGeo::Geographic.spherical_factory(srid: 4326) }
    let(:boundary) do
      factory.polygon(
        factory.linear_ring(
          [
            factory.point(0.5061100423336052, 51.387245941504915),
            factory.point(0.5061945319175742, 51.38713965241118),
            factory.point(0.5062454938888572, 51.387138815488186),
            factory.point(0.5063232779502891, 51.38716141240323),
            factory.point(0.5063809454441092, 51.387173966240084),
            factory.point(0.5064935982227345, 51.38722836616),
            factory.point(0.5064211785793326, 51.387287787537105),
            factory.point(0.5063098669052146, 51.387310384378566),
            factory.point(0.5061100423336052, 51.387245941504915)
          ]
        )
      )
    end
    let(:parsed_enforcement_data) do
      {
        description: "Unauthorised erection of a library in the front garden",
        address_1: "CHARES DICKENS WRITING CHALET–EASTGATE HOUSE–HIGH STREET",
        address_2: nil,
        town: "ROCHESTER",
        county: nil,
        postcode: "ME1 1EW",
        uprn: "000044009430",
        boundary: factory.collection([boundary]),
        lonlat: factory.point(0.506217, 51.3873264)
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
        **parsed_enforcement_data
      )

      expect(enforcement.proposal_details).to all(be_a(ProposalDetail))
      expect(enforcement.proposal_details.size).to eq(expected_proposal_details.size)
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
