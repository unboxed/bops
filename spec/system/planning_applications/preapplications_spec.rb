# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assigning planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  context "when application is a preapp" do
    let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }

    before do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/"
    end

    it "shows preapp services option" do
      expect(page).to have_content("Requested services: Change")
    end

    it "can edit preapp services" do
      within "#additional-services" do
        click_on "Change"
      end

      check "Site visit"
      click_button "Save"
      expect(page).to have_content("Requested services: Site visit Change")
    end
  end

  context "when application is not a preapp" do
    let(:planning_application) { create(:planning_application, :ldc_proposed, local_authority:) }

    before do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/"
    end

    it "does not show preapp services" do
      expect(page).not_to have_content("Requested services:")
    end

    it "cannot edit preapp services" do
      visit "/planning_applications/#{planning_application.reference}/additional_services/edit"
      expect(page).to have_content("Cannot edit pre-application services")
    end
  end
end
