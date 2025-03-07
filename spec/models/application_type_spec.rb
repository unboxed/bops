# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationType do
  describe "class methods" do
    describe "#menu" do
      let!(:local_authority) { create(:local_authority) }
      let!(:lawfulness_certificate) { create(:application_type, local_authority:) }
      let!(:prior_approval) { create(:application_type, :prior_approval, local_authority:) }
      subject { local_authority.application_types }

      it "returns an array of application type names (humanized) and ids" do
        expect(subject.menu).to eq(
          [
            ["Prior Approval - Larger extension to a house", prior_approval.id],
            ["Lawful Development Certificate - Existing use", lawfulness_certificate.id]
          ]
        )
      end

      context "when provided an application type name" do
        let!(:ldc_proposed) { create(:application_type, :ldc_proposed, local_authority:) }
        let!(:prior_approval_part_14) { create(:application_type, :pa_part_14_class_j, local_authority:) }
        let!(:householder) { create(:application_type, :householder, local_authority:) }
        let!(:householder_retrospective) { create(:application_type, :householder_retrospective, local_authority:) }

        it "returns an array of application type names and ids for ldcs only" do
          expect(subject.menu(type: lawfulness_certificate.name)).to eq(
            [
              ["Lawful Development Certificate - Existing use", lawfulness_certificate.id],
              ["Lawful Development Certificate - Proposed use", ldc_proposed.id]
            ]
          )
        end

        it "returns an array of application type names and ids for prior approvals only" do
          expect(subject.menu(type: prior_approval.name)).to eq(
            [
              ["Prior Approval - Install or change solar panels", prior_approval_part_14.id],
              ["Prior Approval - Larger extension to a house", prior_approval.id]
            ]
          )
        end

        it "returns an array of application type names and ids for householder only" do
          expect(subject.menu(type: householder.name)).to eq(
            [
              ["Planning Permission - Full householder", householder.id],
              ["Planning Permission - Full householder retrospective", householder_retrospective.id]
            ]
          )
        end
      end
    end
  end
end
