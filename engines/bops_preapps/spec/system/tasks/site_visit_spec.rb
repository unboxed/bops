# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Allows adding a site visit" do
    within ".bops-sidebar" do
      click_link "Site visit"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/site-visit")
    expect(page).to have_content("No site visits have been recorded yet.")

    within "#new-site-visit-form" do
      fill_in "Day", with: 2
      fill_in "Month", with: 10
      fill_in "Year", with: 2025

      fill_in "Comment", with: "Visited the site to assess proximity to neighbour boundary."
      click_button "Save"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/site-visit")
    expect(planning_application.site_visits.last.comment == "Visited the site to assess proximity to neighbour boundary.")

    expect(page).not_to have_content("No site visits have been recorded yet.")

    within("#site-visit-history") do
      expect(page).to have_content(planning_application.site_visits.last.address)
    end
  end
end
