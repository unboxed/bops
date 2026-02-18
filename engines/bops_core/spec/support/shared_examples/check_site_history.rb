# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "check site history" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path! "check-and-assess/check-application/check-site-history" }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check site history"
    end

    click_button "Save changes"

    expect(task.reload).to be_in_progress
    expect(planning_application.reload.site_history_checked).not_to be true

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed
    expect(planning_application.reload.site_history_checked).to be true
  end

  it "can add a new site history" do
    within ".bops-sidebar" do
      click_link "Check site history"
    end

    find("span", text: "Add a new site history").click

    fill_in "Reference", with: "REF-111"
    fill_in "tasks-check-site-history-form-description-field", with: "Description of a previous planning application"
    choose "Granted"
    fill_in "Day", with: 1
    fill_in "Month", with: 1
    fill_in "Year", with: 2008

    click_button "Add site history"

    expect(task.reload).to be_in_progress

    within("#REF-111") do
      expect(page).to have_selector(".govuk-tag--green", text: "Granted")
      expect(page).to have_content("Description of a previous planning application")
      expect(page).to have_content("Decided on 01/01/2008")
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Site history was successfully marked as reviewed")
    expect(task.reload).to be_completed
  end

  it "can edit a site history", :capybara do
    granted_history = create(:site_history, planning_application:)
    refused_history = create(:site_history, :refused, planning_application:)

    within ".bops-sidebar" do
      click_link "Check site history"
    end

    within("##{granted_history.reference}") do
      expect(page).to have_selector(".govuk-tag--green", text: "Granted")
    end

    within("##{refused_history.reference}") do
      expect(page).to have_selector(".govuk-tag--red", text: "Refused")
    end

    within("##{granted_history.reference}") do
      within(".govuk-summary-card__content") do
        click_link "Edit"
      end
    end

    choose "Other"
    fill_in "site-history-other-decision-field", with: "Withdrawn by applicant"
    fill_in "Address", with: "123 New Street SE1 1AA"
    click_button "Update site history"

    expect(page).to have_content("Site history was successfully updated")

    within("##{granted_history.reference}") do
      expect(page).to have_selector(".govuk-tag--grey", text: "Withdrawn by applicant")
      expect(page).to have_content("Address: 123 New Street SE1 1AA")
    end
  end

  it "can delete a site history", :capybara do
    site_history = create(:site_history, planning_application:)

    within ".bops-sidebar" do
      click_link "Check site history"
    end

    within("##{site_history.reference}") do
      expect(page).to have_content(site_history.description)

      within(".govuk-summary-card__content") do
        accept_confirm do
          click_link "Remove"
        end
      end
    end

    expect(page).to have_content("Site history was successfully removed")
    expect(page).not_to have_selector("##{site_history.reference}")
    expect(page).to have_content("There is no site history for this property.")
  end
end
