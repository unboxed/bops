# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Evidence of immunity" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, :with_immunity, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when signed in as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when planning application is in assessment" do
      it "I can view the information on the evidence of immunity page" do
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "Not started"
        )

        click_link("Evidence of immunity")

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Evidence of immunity")
        end

        expect(page).to have_current_path(
          new_planning_application_immunity_detail_path(planning_application)
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Evidence of immunity")
        end
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

        expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
        expect(page).to have_content("Have the works been completed? Yes")
        expect(page).to have_content("When were the works completed? 01/02/2015")
        expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
        expect(page).to have_content("Has enforcement action been taken about these changes? No")
      end

      it "I can save and come back later when adding or editing the immunity evidence" do
        click_link "Check and assess"
        click_link "Evidence of immunity"

        click_button "Save and come back later"

        expect(page).to have_content("Evidence of immunity successfully updated")

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "In progress"
        )

        click_link("Evidence of immunity")

        click_button "Save and come back later"
        expect(page).to have_content("Evidence of immunity successfully updated")

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "In progress"
        )

        click_link("Application")

        expect(list_item("Check and assess")).to have_content("In progress")
      end

      it "I can save and mark as complete when adding the permitted development right" do
        click_link "Check and assess"
        click_link "Evidence of immunity"

        click_button "Save and mark as complete"

        expect(page).to have_content("Evidence of immunity successfully updated")

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "Completed"
        )
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit planning_application_path(planning_application)

      expect(page).not_to have_link("Evidence of immunity")

      visit new_planning_application_immunity_detail_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
