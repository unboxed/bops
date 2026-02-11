# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check application details task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-application-details") }

  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  before do
    sign_in(user)

    visit("/preapps/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    expect(page).to have_selector("h1", text: "Check application details")
  end

  it_behaves_like "check application details form links"
  it_behaves_like "check application details requesting additional document"

  it "can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "Yes"
    end
    within_fieldset("Are the plans consistent with each other?") do
      choose "Yes"
    end
    within_fieldset("Are the proposal details consistent with the plans?") do
      choose "Yes"
    end
    within_fieldset("Is the site map correct?") do
      choose "Yes"
    end

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

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "Yes"
    end
    within_fieldset("Are the plans consistent with each other?") do
      choose "Yes"
    end
    within_fieldset("Are the proposal details consistent with the plans?") do
      choose "No"
    end
    within_fieldset("Is the site map correct?") do
      choose "No"
    end
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

  it "lets the user request a description change" do
    travel_to(Time.zone.local(2022, 9, 15, 12))

    within ".bops-sidebar" do
      click_link "Check application details"
    end

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "No"
    end

    click_link "Request a change to the description"

    fill_in "Enter an amended description", with: "New description"
    click_button "Save and mark as complete"

    expect(page).to have_content("Description updated")
    expect(planning_application.reload.description).to eq("New description")
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

      within ".bops-sidebar" do
        click_link "Check application details"
      end
    end

    it_behaves_like "check application details with existing additional document request"
  end
end
