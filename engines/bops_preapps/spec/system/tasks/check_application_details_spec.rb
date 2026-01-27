# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check application details task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-application-details") }

  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") { choose "Yes" }
    within_fieldset("Are the plans consistent with each other?") { choose "Yes" }
    within_fieldset("Are the proposal details consistent with the plans?") { choose "Yes" }
    within_fieldset("Is the site map correct?") { choose "Yes" }

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    expect(planning_application.consistency_checklist.description_matches_documents).to eq "yes"
    expect(planning_application.consistency_checklist.documents_consistent).to eq "yes"
    expect(planning_application.consistency_checklist.proposal_details_match_documents).to eq "yes"
    expect(planning_application.consistency_checklist.site_map_correct).to eq "yes"
  end

  it "persists radio button selections when viewing the page again" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") { choose "Yes" }
    within_fieldset("Are the plans consistent with each other?") { choose "Yes" }
    within_fieldset("Are the proposal details consistent with the plans?") { choose "No" }
    within_fieldset("Is the site map correct?") { choose "No" }
    fill_in "Add a comment", with: "Site boundary needs adjusting"

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") do
      expect(page).to have_checked_field("Yes")
    end

    within_fieldset("Are the plans consistent with each other?") do
      expect(page).to have_checked_field("Yes")
    end

    within_fieldset("Are the proposal details consistent with the plans?") do
      expect(page).to have_checked_field("No")
    end

    within_fieldset("Is the site map correct?") do
      expect(page).to have_checked_field("No")
    end

    expect(page).to have_field("Add a comment", with: "Site boundary needs adjusting")
  end

  it "shows link to request a description change when selecting No" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") { choose "No" }

    expect(page).to have_link("Request a change to the description")
  end

  it "shows link to request an additional document when selecting No" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Are the plans consistent with each other?") { choose "No" }

    expect(page).to have_link("Request a new document")
  end

  it "lets the user request a description change" do
    travel_to(Time.zone.local(2022, 9, 15, 12))

    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") { choose "No" }

    click_link "Request a change to the description"

    fill_in "Enter an amended description", with: "New description"
    click_button "Save and mark as complete"

    expect(page).to have_content("Description updated")
    expect(planning_application.reload.description).to eq("New description")
  end

  it "lets the user request an additional document" do
    travel_to(Time.zone.local(2022, 9, 15, 12))

    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Are the plans consistent with each other?") { choose "No" }

    click_link "Request a new document"

    fill_in "Please specify the new document type:", with: "New document type"
    fill_in "Please specify the reason you have requested this document?", with: "Reason for new document"
    click_button "Send request"

    expect(page).to have_content("Alice Smith requested a new document")
    expect(page).to have_content("New document type")
    expect(page).to have_content("Reason: Reason for new document")
    expect(page).to have_content("Requested 15 September 2022 12:00")
  end

  it "can navigate to the first task from consultation" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    within ".bops-sidebar" do
      click_link "Assessment"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
  end

  context "when there is an existing additional document request" do
    before do
      create(
        :additional_document_validation_request,
        :closed,
        :with_documents,
        planning_application:
      )
    end

    it "shows the additional document request and lets the user view the document" do
      within ".bops-sidebar" do
        click_link "Check application details"
      end

      expect(page).to have_content("requested a new document")
      click_link "View new document"

      expect(page).to have_content("File name: proposed-floorplan.png")
    end
  end
end
