# frozen_string_literal: true

require "rails_helper"

RSpec.describe OwnershipCertificateCreationService, type: :service do
  include ActionDispatch::TestProcess::FixtureFile

  describe "#call" do
    let!(:planning_application) { create(:planning_application) }

    let!(:params) do
      ActionController::Parameters.new(
        {
          "certificate_type" => "b",
          "land_owners_attributes" => [{
            "name" => "Ross",
            "address_1" => "Flat 1",
            "address_2" => "123 street",
            "town" => "London",
            "postcode" => "E16LT",
            "country" => "UK",
            "notice_given_at" => Time.zone.now
          }]
        }
      )
    end

    let(:create_ownership_certificate) do
      described_class.new(
        planning_application:,
        params:
      ).call
    end

    context "when successful" do
      context "with an already existing ownership certificate" do
        let!(:ownership_certificate) { create(:ownership_certificate, planning_application:, certificate_type: "a") }

        it "updates the certificate" do
          expect do
            create_ownership_certificate
          end.to change(OwnershipCertificate, :count).by(0)

          expect(ownership_certificate).to have_attributes(
            certificate_type: "b"
          )

          land_owner = ownership_certificate.land_owners.first

          expect(land_owner).to have_attributes(
            name: "Ross",
            address_1: "Flat 1",
            address_2: "123 street",
            town: "London",
            postcode: "E16LT",
            country: "UK",
            notice_given: true
          )

          expect(land_owner.notice_given_at).to be_within(1.second).of(Time.zone.now)
        end
      end

      context "with no existing ownership certificate" do
        it "creates a new certificate" do
          expect do
            create_ownership_certificate
          end.to change(OwnershipCertificate, :count).by(1)

          ownership_certificate = OwnershipCertificate.last

          expect(ownership_certificate).to have_attributes(
            certificate_type: "b"
          )

          land_owner = ownership_certificate.land_owners.first

          expect(land_owner).to have_attributes(
            name: "Ross",
            address_1: "Flat 1",
            address_2: "123 street",
            town: "London",
            postcode: "E16LT",
            country: "UK",
            notice_given: true
          )

          expect(land_owner.notice_given_at).to be_within(1.second).of(Time.zone.now)
        end
      end
    end

    context "when unsuccessful" do
      let!(:params) do
        ActionController::Parameters.new(
          "certificate_type" => "",
          "land_owners_attributes" => [{}]
        )
      end

      it "raises an error" do
        expect { create_ownership_certificate }.to raise_error(described_class::CreateError)
      end
    end
  end
end
