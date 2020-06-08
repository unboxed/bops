# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Drawings index page", type: :system do
  fixtures :sites

  let!(:site) { sites(:elm_grove) }

  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           site: site,
           reference: "19/AP/1880"
  end

  let!(:drawing) do
    create :drawing, :with_plan,
           planning_application: planning_application
  end

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit planning_application_path(planning_application)
      click_button 'Proposal documents'
      click_link 'Manage documents'
    end

    scenario "Application reference is displayed on page" do
        expect(page).to have_text "19/AP/1880"
    end

    scenario "Application address is displayed on page" do
      expect(page).to have_text "7 Elm Grove"
    end

    scenario "Plan image is the only one on the page" do
      expect(all("img").count).to eq(1)
    end

    scenario "Plan image opens in new tab" do
      find(:css, 'a[href*="active"]').click
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      expect(current_url).to include("/rails/active_storage/")
    end

    scenario "User can log out from drawings page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end
end
