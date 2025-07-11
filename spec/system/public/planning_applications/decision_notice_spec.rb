# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Decision notice" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:planning_application) do
    create(:planning_application, :determined, application_type:, local_authority:, decision:)
  end
  let(:decision) { "granted" }

  context "when not logged in" do
    before do
      visit "/public/planning_applications/#{planning_application.reference}/decision_notice"
    end

    context "when planning application has been determined" do
      it "shows a publicly available decision notice" do
        expect(page).to have_content("Decision notice")

        within(".govuk-tag.govuk-tag--green") do
          expect(page).to have_content("Granted")
        end

        expect(page).to have_css(".decision-notice")
      end

      context "when decision is to grant" do
        it "shows conditions on the notice" do
          expect(page).to have_selector("h3", text: "Conditions:")
        end
      end

      context "when decision is to refuse" do
        let(:decision) { "refused" }

        it "does not show conditions on the notice" do
          expect(page).not_to have_selector("h3", text: "Conditions:")
        end
      end
    end

    context "when planning application has not been determined" do
      let!(:planning_application) do
        create(:planning_application, :awaiting_determination, local_authority:)
      end

      it "shows a not found page" do
        expect(page).not_to have_content("Decision notice")
        expect(page).to have_content("Not Found")
      end
    end
  end

  context "when logged in" do
    let(:user) { create(:user, local_authority:) }

    before do
      sign_in(user)

      visit "/public/planning_applications/#{planning_application.reference}/decision_notice"
    end

    it "is accessible" do
      expect(page).to have_content("Decision notice")
    end
  end
end
