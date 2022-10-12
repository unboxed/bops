# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :in_assessment, local_authority: default_local_authority
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when planning application is in assessment" do
    it "I can view the information on the permitted development rights page" do
      click_link "Check and assess"

      within("#check-consistency-assessment-tasks") do
        within("#permitted-development-right-tasklist") do
          expect(page).to have_content("Not started")
          click_link "Permitted development rights"
        end
      end

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Permitted development rights")
      end

      expect(page).to have_current_path(
        new_planning_application_permitted_development_right_path(planning_application)
      )

      within(".govuk-heading-l") do
        expect(page).to have_content("Permitted development rights")
      end
      expect(page).to have_content("Application number: #{planning_application.reference}")
      expect(page).to have_content(planning_application.full_address.upcase)

      within(".govuk-warning-text") do
        expect(page).to have_content("This information WILL be made public")
      end

      within("#constraints-section") do
        expect(page).to have_content("Constraints - including Article 4 direction(s)")
      end

      within("#planning-history-section") do
        expect(page).to have_content("Planning history")
      end
    end

    it "there is a validation error when submitting an empty text field when selecting 'Yes'" do
      click_link "Check and assess"
      click_link "Permitted development rights"
      choose "Yes"

      click_button "Save and mark as complete"
      within(".govuk-error-summary") do
        expect(page).to have_content "Removed reason can't be blank"
      end

      click_button "Save and come back later"
      within(".govuk-error-summary") do
        expect(page).to have_content "Removed reason can't be blank"
      end
    end

    it "there is no validation error when submitting an empty text field when selecting 'No'" do
      click_link "Check and assess"
      click_link "Permitted development rights"
      choose "No"

      click_button "Save and mark as complete"
      expect(page).to have_content("Permitted development rights response was successfully created")
    end

    it "I can save and come back later when adding or editing the permitted development right" do
      click_link "Check and assess"
      click_link "Permitted development rights"

      choose "Yes"
      fill_in "permitted_development_right[removed_reason]", with: "A reason"
      click_button "Save and come back later"

      expect(page).to have_content("Permitted development rights response was successfully created")

      within("#permitted-development-right-tasklist") do
        expect(page).to have_content("In progress")
        click_link "Permitted development rights"
      end

      within(".govuk-warning-text") do
        expect(page).to have_content("This information WILL be made public")
      end

      within("#constraints-section") do
        expect(page).to have_content("Constraints - including Article 4 direction(s)")
      end

      within("#planning-history-section") do
        expect(page).to have_content("Planning history")
      end

      fill_in "permitted_development_right[removed_reason]", with: "Another reason"

      click_button "Save and come back later"
      expect(page).to have_content("Permitted development rights response was successfully updated")

      within("#permitted-development-right-tasklist") do
        expect(page).to have_content("In progress")
      end

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end

    it "I can save and mark as complete when adding the permitted development right" do
      click_link "Check and assess"
      click_link "Permitted development rights"

      choose "Yes"
      fill_in "permitted_development_right[removed_reason]", with: "A reason"
      click_button "Save and mark as complete"

      expect(page).to have_content("Permitted development rights response was successfully created")

      within("#permitted-development-right-tasklist") do
        expect(page).to have_content("Removed")
      end

      click_link "Permitted development rights"
      expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
      expect(page).to have_content("Yes")
      expect(page).to have_content("A reason")

      click_link "Edit permitted development rights"
      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Permitted development rights response was successfully updated")

      within("#permitted-development-right-tasklist") do
        expect(page).to have_content("Checked")
      end

      click_link "Permitted development rights"
      expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
      expect(page).to have_content("No")
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: default_local_authority
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("Permitted development rights")

      visit new_planning_application_permitted_development_right_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
