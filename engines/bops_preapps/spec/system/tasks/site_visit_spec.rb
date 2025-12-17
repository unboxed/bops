# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/additional-services/site-visit") }

  let(:user) { create(:user, local_authority:) }
  let(:tomorrow) { Date.tomorrow }

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
      click_button "Add site visit"
    end

    expect(page).to have_content("Enter the date of the site visit")
    expect(page).to have_content("Enter some comments about the site visit")

    within "#new-site-visit-form" do
      fill_in "Day", with: 32
      fill_in "Month", with: 12
      fill_in "Year", with: 2025

      click_button "Add site visit"
    end

    expect(page).to have_content("Enter a valid date for the site visit")

    within "#new-site-visit-form" do
      fill_in "Day", with: tomorrow.day
      fill_in "Month", with: tomorrow.month
      fill_in "Year", with: tomorrow.year

      click_button "Add site visit"
    end

    expect(page).to have_content("Enter a date on or before today’s date")

    within "#new-site-visit-form" do
      fill_in "Day", with: 2
      fill_in "Month", with: 10
      fill_in "Year", with: 2025

      fill_in "Comment", with: "Visited the site to assess proximity to neighbour boundary."
      click_button "Add site visit"
    end

    click_button "Save changes"

    expect(task.reload).to be_in_progress

    expect(planning_application.site_visits.last.comment == "Visited the site to assess proximity to neighbour boundary.")

    expect(page).not_to have_content("No site visits have been recorded yet.")

    within("#site-visit-history") do
      expect(page).to have_content(planning_application.site_visits.last.address)
    end

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/site-visit")
  end

  it "displays uploaded photos in the site visit history" do
    create(
      :site_visit,
      :with_documents,
      planning_application:,
      created_by: user,
      visited_at: 1.day.ago,
      address: planning_application.address,
      comment: "Site inspection completed"
    )

    within ".bops-sidebar" do
      click_link "Site visit"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/site-visit")

    within("#site-visit-history") do
      expect(page).to have_content("Site inspection completed")
      expect(page).to have_link("View in new window")
      expect(page).to have_css("img")
    end
  end
end
