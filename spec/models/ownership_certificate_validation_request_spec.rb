# frozen_string_literal: true

require "rails_helper"

RSpec.describe OwnershipCertificateValidationRequest do
  include_examples "ValidationRequest", described_class, "ownership_certificate_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:ownership_certificate_validation_request) }
  end

  describe "validations" do
    subject(:ownership_certificate_validation_request) { described_class.new }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { ownership_certificate_validation_request.planning_application = planning_application }

    describe "#reason" do
      it "validates presence" do
        expect do
          ownership_certificate_validation_request.valid?
        end.to change {
          ownership_certificate_validation_request.errors[:reason]
        }.to ["Provide a reason for changes"]
      end
    end
  end

  describe "scopes" do
    describe "callbacks" do
      describe "::on_create #allows_only_one_open_ownership_certificate_change!" do
        let(:planning_application) { create(:planning_application, :not_started) }
        let!(:ownership_certificate_validation_request) do
          create(:ownership_certificate_validation_request, planning_application:, state: "open")
        end

        it "prevents an ownership_certificate_validation_request from being created" do
          other_request = build(:ownership_certificate_validation_request, planning_application:)
          expect do
            other_request.save!
          end.to raise_error(ActiveRecord::RecordInvalid,
            "Validation failed: An ownership certificate change request already exists for this planning application.")
        end
      end
    end
  end
end
