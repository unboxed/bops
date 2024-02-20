# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::OwnershipCertificateComponent, type: :component do
  context "when planning application is not validated" do
    let(:planning_application) do
      build(:planning_application, :not_started, valid_ownership_certificate:)
    end

    context "when ownership certificate has not been marked as valid" do
      let(:valid_ownership_certificate) { nil }

      before do
        render_inline(
          described_class.new(planning_application:)
        )
      end

      it "renders 'Not started' status" do
        expect(page).to have_content("Not started")
      end
    end

    context "when ownership certificate has been marked as valid" do
      let(:valid_ownership_certificate) { true }

      before do
        create(:ownership_certificate, planning_application:)

        render_inline(
          described_class.new(planning_application:)
        )
      end

      it "renders 'Valid' status" do
        expect(page).to have_content("Valid")
      end
    end

    context "when ownership certificate has been marked as invalid" do
      let(:valid_ownership_certificate) { false }

      before do
        create(:ownership_certificate, planning_application:)

        render_inline(
          described_class.new(planning_application:)
        )
      end

      it "renders 'Invalid' status" do
        expect(page).to have_content("Invalid")
      end
    end

    context "when ownership certificate is missing and has been marked as invalid" do
      let(:valid_ownership_certificate) { false }

      before do
        create(:ownership_certificate_validation_request, planning_application:, reason: "invalid")

        render_inline(
          described_class.new(planning_application:)
        )
      end

      it "renders 'Invalid' status" do
        expect(page).to have_content("Invalid")
      end
    end

    context "when ownership certificate has an updated validation request" do
      let(:valid_ownership_certificate) { false }

      before do
        create(:ownership_certificate, planning_application:)
        create(:ownership_certificate_validation_request, planning_application:, reason: "invalid")

        render_inline(
          described_class.new(planning_application:)
        )
      end

      it "renders 'Updated' status" do
        expect(page).to have_content("Updated")
      end
    end
  end

  context "when planning application is in assessment" do
    let(:planning_application) do
      build(:planning_application, :in_assessment, valid_ownership_certificate:)
    end

    context "when ownership certificate is not present" do
      let(:valid_ownership_certificate) { true }

      it "renders 'Not started' status" do
        render_inline(
          described_class.new(planning_application:)
        )

        expect(page).to have_content("Not started")
      end
    end

    context "when assessor has marked certificate as valid" do
      let(:valid_ownership_certificate) { true }

      before do
        ownership_certificate = create(:ownership_certificate, planning_application:)
        ownership_certificate.current_review.update(status: "complete")
      end

      it "renders 'Valid' status" do
        render_inline(
          described_class.new(planning_application:)
        )

        expect(page).to have_content("Valid")
      end
    end

    context "when ownership certificate has been marked as invalid" do
      context "when the applicant has accepted the changes" do
        let(:valid_ownership_certificate) { true }

        before do
          ownership_certificate = create(:ownership_certificate, planning_application:)
          ownership_certificate.current_review.update(status: "complete")
        end

        it "renders 'Invalid' status" do
          render_inline(
            described_class.new(planning_application:)
          )

          expect(page).to have_content("Valid")
        end
      end

      context "when the applicant has not accepted the changes" do
        let(:valid_ownership_certificate) { false }

        before do
          ownership_certificate = create(:ownership_certificate, planning_application:)
          ownership_certificate.current_review.update(status: "complete")
        end

        it "renders 'Invalid' status" do
          render_inline(
            described_class.new(planning_application:)
          )

          expect(page).to have_content("Invalid")
        end
      end
    end

    context "when ownership certificate has open validation requests" do
      let(:valid_ownership_certificate) { false }

      before do
        create(:ownership_certificate, planning_application:)
        create(:ownership_certificate_validation_request, planning_application:, reason: "invalid")
      end

      it "renders 'Updated' status" do
        render_inline(
          described_class.new(planning_application:)
        )

        expect(page).to have_content("Invalid")
      end
    end
  end
end
