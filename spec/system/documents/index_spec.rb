# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Documents index page", type: :system do
  let!(:site) { create :site, address_1: "7 Elm Grove" }
  let(:local_authority) { create :local_authority }
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           site: site,
           local_authority: local_authority
  end

  let!(:document) do
    create :document, :with_file,
           planning_application: planning_application
  end

  context "as a user who is not logged in" do
    scenario "User is redirected to login page" do
      visit planning_application_documents_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button 'Proposal documents'
      click_link 'Manage documents'
    end

    scenario "Application reference is displayed on page" do
      expect(page).to have_text planning_application.reference
    end

    scenario "Application address is displayed on page" do
      expect(page).to have_text "7 Elm Grove"
    end

    scenario "File image is the only one on the page" do
      expect(all("img").count).to eq(1)
    end

    scenario "Document management page does not contain accordion" do
      expect(page).not_to have_text("Application information")
    end

    scenario "File image opens in new tab" do
      click_link 'View in new window'
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)

      expect(current_url).to include("/rails/active_storage/")
    end

    scenario "User can log out from documents page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end
end
