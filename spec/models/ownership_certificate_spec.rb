# frozen_string_literal: true

require "rails_helper"

RSpec.describe OwnershipCertificate do
  describe "validations" do
    subject(:ownership_certificate) { described_class.new }

    let!(:planning_application) { create(:planning_application, :not_started) }

    before { ownership_certificate.planning_application = planning_application }

    describe "#certificate_type" do
      it "validates presence" do
        expect do
          ownership_certificate.valid?
        end.to change {
          ownership_certificate.errors[:certificate_type]
        }.to ["can't be blank"]
      end
    end
  end
end
