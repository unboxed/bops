# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assigning planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }

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

  context "when pre-app is not started" do
    let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

    it "correctly displays index task list to an assessor" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/"

      within("#validation-section") do
        expect(page).to have_selector("li:first-child a", text: "Check and validate")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
      end

      within("#consultation-section") do
        expect(page).to have_selector("li:first-child a", text: "Consultees")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
      end

      within("#assess-section") do
        expect(page).to have_selector("li:first-child", text: "Check and assess")
        expect(page).to have_selector("li:first-child", text: "Cannot start yet")
      end

      within("#review-section") do
        expect(page).to have_selector("li:first-child", text: "View recommendation")
        expect(page).to have_selector("li:first-child", text: "Cannot start yet")
      end
    end
  end

  context "when pre-app is in assessment", :capybara do
    let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }

    it "correctly displays index task list to an reviewer" do
      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/"

      within("#validation-section") do
        expect(page).to have_selector("li:first-child a", text: "Check and validate")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Completed")
      end

      within("#review-section") do
        expect(page).to have_selector("li:first-child a", text: "Review and sign-off")
        expect(page).not_to have_selector("li:first-child", text: "Cannot start yet")
      end
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
