# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check application details task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:, name: "Alice Smith") }
  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:)
  end

  let(:task) do
    planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-application-details")
  end

  before do
    sign_in(user)
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    expect(page).to have_selector("h1", text: "Check application details")
  end

  it_behaves_like "check application details form links"
  it_behaves_like "check application details requesting additional document"

  it "can complete and submit the form" do
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

    expect(page).to have_content("Application details were successfully checked")
    expect(task.reload).to be_completed

    expect(planning_application.consistency_checklist.description_matches_documents).to eq "yes"
    expect(planning_application.consistency_checklist.documents_consistent).to eq "yes"
    expect(planning_application.consistency_checklist.proposal_details_match_documents).to eq "yes"
    expect(planning_application.consistency_checklist.site_map_correct).to eq "yes"
  end

  it "persists radio button selections when viewing the page again" do
    within_fieldset("Does the description match the development or use in the plans?") do
      choose "Yes"
    end
    within_fieldset("Are the plans consistent with each other?") do
      choose "Yes"
    end
    within_fieldset("Are the proposal details consistent with the plans?") do
      choose "No"
    end
    fill_in "How are the proposal details inconsistent?", with: "Reason for inconsistency"
    within_fieldset("Is the site map correct?") do
      choose "Yes"
    end

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

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
      expect(page).to have_checked_field("Yes")
    end
  end

  it "lets the user request a description change with applicant approval" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "No"
    end
    click_link "Request a change to the description"

    expect(page).to have_selector("h1", text: "Check description")

    choose "No"
    fill_in "Enter an amended description", with: "New description"
    choose "Yes, applicant agreement needed"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    expect(page).not_to have_link("Request a change to the description")
    expect(page).to have_content("Alice Smith requested a new description")
    expect(page).to have_content("Proposed description: New description")
    expect(page).to have_content("Proposed 15 September 2022 12:00")

    request = planning_application.description_change_validation_requests.last
    expect(request).to be_post_validation
  end

  it "lets the user request a description change without applicant approval" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "No"
    end
    click_link "Request a change to the description"

    expect(page).to have_selector("h1", text: "Check description")

    choose "No"
    fill_in "Enter an amended description", with: "Updated description"
    choose "No, update description immediately"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    expect(planning_application.reload.description).to eq("Updated description")

    request = planning_application.description_change_validation_requests.last
    expect(request).to be_post_validation
  end

  it "creates additional document requests as post_validation" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    within_fieldset("Are the plans consistent with each other?") do
      choose "No"
    end
    click_link "Request a new document"

    fill_in "Please specify the new document type:", with: "Floor plan"
    fill_in "Please specify the reason you have requested this document?", with: "Missing from submission"
    click_button "Send request"

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    request = planning_application.additional_document_validation_requests.last
    expect(request).to be_post_validation
  end

  it "redirects back to check-application-details after completing check-description via return_to" do
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    within_fieldset("Does the description match the development or use in the plans?") do
      choose "No"
    end
    click_link "Request a change to the description"

    expect(page).to have_selector("h1", text: "Check description")
    expect(page).to have_current_path(%r{return_to=})

    choose "No"
    fill_in "Enter an amended description", with: "Updated description"
    choose "No, update description immediately"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    expect(page).to have_selector("h1", text: "Check application details")
  end

  context "when there is an open additional document request" do
    before do
      create(
        :additional_document_validation_request,
        :open,
        :post_validation,
        planning_application:,
        user:
      )

      visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    end

    it "redirects back to check-application-details after cancelling the request" do
      click_link "Cancel request"

      expect(page).to have_current_path(%r{return_to=})
      expect(page).to have_content("Cancel validation request")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
      expect(page).to have_selector("h1", text: "Check application details")
    end
  end

  context "when there is an existing additional document request" do
    before do
      create(
        :additional_document_validation_request,
        :closed,
        :with_documents,
        planning_application:
      )

      visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
    end

    it_behaves_like "check application details with existing additional document request"
  end
end
