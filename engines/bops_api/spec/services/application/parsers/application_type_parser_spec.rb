# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::ApplicationTypeParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let!(:application_type_pa) { create(:application_type, :prior_approval, local_authority:) }
    let!(:application_type_ldce) { create(:application_type, :ldc_existing, local_authority:) }
    let!(:application_type_ldcp) { create(:application_type, :ldc_proposed, local_authority:) }
    let!(:application_type_pp) { create(:application_type, :planning_permission, local_authority:) }

    let(:parse_application_type) do
      described_class.new(params, local_authority:).parse
    end

    context "when application type is LDCE" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_lawful_development_certificate_existing.json").read)
        )[:data][:application][:type]
      }

      it "returns the correct application type" do
        expect(parse_application_type).to eq(application_type: application_type_ldce)
      end
    end

    context "when application type is LDCP" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_lawful_development_certificate_proposed.json").read)
        )[:data][:application][:type]
      }

      it "returns the correct application type" do
        expect(parse_application_type).to eq(application_type: application_type_ldcp)
      end
    end

    context "when application type is prior approval part1 classA" do
      let(:params) { {value: "pa.part1.classA"} }

      it "returns the correct application type" do
        expect(parse_application_type).to eq(
          application_type: application_type_pa
        )
      end
    end

    context "when application type is planning permission full householder" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:application][:type]
      }

      it "returns the correct application type" do
        expect(parse_application_type).to eq(
          application_type: application_type_pp
        )
      end
    end

    context "when application type does not exist" do
      let(:params) { {value: "pp.full.minor"} }

      it "raises an error" do
        expect { parse_application_type }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
