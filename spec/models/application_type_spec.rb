# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationType do
  describe "#validations" do
    subject(:application_type) { described_class.new }

    describe "#name" do
      it "validates presence" do
        expect { application_type.valid? }.to change { application_type.errors[:name] }.to ["can't be blank"]
      end
    end
  end

  describe "class methods" do
    describe "#menu" do
      let!(:lawfulness_certificate) { create(:application_type, name: "lawfulness_certificate") }
      let!(:prior_approval) { create(:application_type, name: "prior_approval") }

      it "returns an array of application type names (humanized) and ids" do
        expect(described_class.menu).to eq(
          [["Prior approval", prior_approval.id], ["Lawfulness certificate", lawfulness_certificate.id]]
        )
      end
    end
  end
end
