# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Decision notice" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(:planning_application, :determined, local_authority: default_local_authority, decision: "granted")
  end

  context "when not logged in" do
    before do
      visit decision_notice_public_planning_application_path(planning_application)
    end

    context "when planning application has been determined" do
      it "shows a publicly available decision notice" do
        expect(page).to have_content("Decision notice")

        within(".govuk-tag.govuk-tag--green") do
          expect(page).to have_content("Granted")
        end

        expect(page).to have_css(".decision-notice")
      end
    end

    context "when planning application has not been determined" do
      let!(:planning_application) do
        create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
      end

      it "shows a not found page" do
        expect(page).not_to have_content("Decision notice")
        expect(page).to have_content("Not Found")
      end
    end
  end

  context "when logged in" do
    let(:user) { create(:user, local_authority: default_local_authority) }

    before do
      sign_in(user)

      visit decision_notice_public_planning_application_path(planning_application)
    end

    it "is accessible" do
      expect(page).to have_content("Decision notice")
    end
  end
end
