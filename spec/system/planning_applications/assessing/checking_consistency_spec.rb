# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking consistency" do
  let(:local_authority) { create(:local_authority, :default) }

  let(:user) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Alice Smith"
    )
  end

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority:
    )
  end

  before do
    sign_in(user)
    visit(planning_application_path(planning_application))
  end

  context "when the application is an LDC" do
    it "lets user save draft or mark as complete" do
      expect(list_item("Check and assess")).to have_content("Not started")
      click_link("Check and assess")
      click_link("Check description, documents and proposal details")
      click_button("Save and mark as complete")

      expect(page).to have_content(
        "Determine whether the description matches the development or use in the plans"
      )

      expect(page).to have_content(
        "Determine whether the proposal details are consistent with the plans"
      )

      expect(page).to have_content(
        "Determine whether the plans are consistent with each other"
      )

      form_group1 = form_group_with_legend(
        "Is the red line on the site map correct for the site and proposed works?"
      )

      within(form_group1) { choose("Yes") }

      form_group2 = form_group_with_legend(
        "Does the description match the development or use in the plans?"
      )

      within(form_group2) { choose("Yes") }

      form_group3 = form_group_with_legend(
        "Are the plans consistent with each other?"
      )

      within(form_group3) { choose("Yes") }
      click_button("Save and come back later")

      expect(page).to have_content("Successfully updated application checklist")

      expect(task_list_item).to have_content("In progress")

      click_link("Check description, documents and proposal details")

      form_group4 = form_group_with_legend(
        "Are the proposal details consistent with the plans?"
      )

      within(form_group4) { choose("No") }

      fill_in(
        "How are the proposal details inconsistent?",
        with: "Reason for inconsistencty"
      )

      click_button("Save and mark as complete")

      expect(page).to have_content("Successfully updated application checklist")

      expect(task_list_item).to have_content("Completed")

      click_link("Check description, documents and proposal details")

      field1 = find_by_id(
        "consistency-checklist-description-matches-documents-yes-field"
      )

      field2 = find_by_id("consistency-checklist-documents-consistent-yes-field")

      field3 = find_by_id(
        "consistency-checklist-proposal-details-match-documents-no-field"
      )

      expect(field1).to be_disabled
      expect(field1).to be_checked
      expect(field2).to be_disabled
      expect(field2).to be_checked
      expect(field3).to be_disabled
      expect(field3).to be_checked

      expect(page).not_to have_field(
        "How are the proposal details inconsistent?",
        with: "Reason for inconsistencty"
      )

      expect(page).to have_content("How are the proposal details inconsistent?")
      expect(page).to have_content("Reason for inconsistencty")

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end
  end

  context "when the application is a prior approval" do
    before do
      type = create(:application_type, :prior_approval)
      planning_application.update(application_type: type)
      create(:proposal_measurement, planning_application:)
    end

    it "lets user save draft or mark as complete" do
      expect(list_item("Check and assess")).to have_content("Not started")
      click_link("Check and assess")
      click_link("Check description, documents and proposal details")
      click_button("Save and mark as complete")

      expect(page).to have_content(
        "Determine whether the description matches the development or use in the plans"
      )

      expect(page).to have_content(
        "Determine whether the proposal details are consistent with the plans"
      )

      expect(page).to have_content(
        "Determine whether the plans are consistent with each other"
      )

      form_group1 = form_group_with_legend(
        "Is the red line on the site map correct for the site and proposed works?"
      )

      within(form_group1) { choose("Yes") }

      form_group2 = form_group_with_legend(
        "Does the description match the development or use in the plans?"
      )

      within(form_group2) { choose("Yes") }

      form_group3 = form_group_with_legend(
        "Are the plans consistent with each other?"
      )

      within(form_group3) { choose("Yes") }
      click_button("Save and come back later")

      expect(page).to have_content("Successfully updated application checklist")

      expect(task_list_item).to have_content("In progress")

      click_link("Check description, documents and proposal details")

      form_group4 = form_group_with_legend(
        "Are the proposal details consistent with the plans?"
      )

      within(form_group4) { choose("No") }

      fill_in(
        "How are the proposal details inconsistent?",
        with: "Reason for inconsistencty"
      )

      form_group5 = form_group_with_legend(
        "Do the measurements submitted by the applicant match the drawings?"
      )

      within(form_group5) { choose("No") }

      fill_in(
        "Eaves height",
        with: "6.0"
      )

      click_button("Save and mark as complete")

      expect(page).to have_content("Successfully updated application checklist")

      expect(task_list_item).to have_content("Completed")

      click_link("Check description, documents and proposal details")

      field1 = find_by_id(
        "consistency-checklist-description-matches-documents-yes-field"
      )

      field2 = find_by_id("consistency-checklist-documents-consistent-yes-field")

      field3 = find_by_id(
        "consistency-checklist-proposal-details-match-documents-no-field"
      )

      field4 = find_by_id(
        "consistency-checklist-proposal-measurements-match-documents-no-field"
      )

      expect(field1).to be_disabled
      expect(field1).to be_checked
      expect(field2).to be_disabled
      expect(field2).to be_checked
      expect(field3).to be_disabled
      expect(field3).to be_checked
      expect(field4).to be_checked
      expect(field4).to be_checked

      expect(page).not_to have_field(
        "How are the proposal details inconsistent?",
        with: "Reason for inconsistencty"
      )

      expect(page).to have_content("How are the proposal details inconsistent?")
      expect(page).to have_content("Reason for inconsistencty")

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end
  end

  it "lets the user request a description change" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    click_link("Check and assess")
    click_link("Check description, documents and proposal details")

    form_group = form_group_with_legend(
      "Does the description match the development or use in the plans?"
    )

    within(form_group) { choose("No") }
    click_link("Request a change to the description")

    fill_in(
      "Please suggest a new application description",
      with: "New description"
    )

    click_button("Send")

    expect(page).to have_content(
      "Description change request successfully sent."
    )

    expect(page).not_to have_link("Request a change to the description")
    expect(page).to have_content("Alice Smith requested a new description")
    expect(page).to have_content("Proposed description: New description")
    expect(page).to have_content("Proposed 15 September 2022 12:00")

    click_link("View and edit request")
    click_button("Cancel this request")

    expect(page).to have_content("Description change request successfully cancelled.")

    expect(page).to have_content("Cancelled 15 September 2022 12:00")

    travel_to(Time.zone.local(2022, 9, 15, 13))

    form_group = form_group_with_legend(
      "Does the description match the development or use in the plans?"
    )

    within(form_group) { choose("No") }
    click_link("Request a change to the description")

    fill_in(
      "Please suggest a new application description",
      with: "New description 2"
    )

    click_button("Send")

    expect(page).to have_content(
      "Description change request successfully sent."
    )

    expect(page).not_to have_link("Request a change to the description")
    expect(page).to have_content("Proposed description: New description 2")
    expect(page).to have_content("Proposed 15 September 2022 13:00")

    planning_application
      .description_change_validation_requests
      .open
      .last
      .auto_close_request!

    visit(planning_application_assessment_tasks_path(planning_application))
    click_link("Check description, documents and proposal details")

    expect(page).to have_content("Accepted 15 September 2022 13:00")

    travel_to(Time.zone.local(2022, 9, 15, 14))

    form_group = form_group_with_legend(
      "Does the description match the development or use in the plans?"
    )

    within(form_group) { choose("No") }
    click_link("Request a change to the description")

    fill_in(
      "Please suggest a new application description",
      with: "New description 3"
    )

    click_button("Send")

    expect(page).to have_content(
      "Description change request successfully sent."
    )

    expect(page).not_to have_link("Request a change to the description")
    expect(page).to have_content("Proposed description: New description 3")
    expect(page).to have_content("Proposed 15 September 2022 14:00")

    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Description change requests must be closed or cancelled"
    )

    request = planning_application
              .description_change_validation_requests
              .open
              .last

    request.close!
    request.update!(approved: true)
    visit(planning_application_assessment_tasks_path(planning_application))
    click_link("Check description, documents and proposal details")

    expect(page).to have_content("Accepted 15 September 2022 14:00")
    expect(page).to have_link("Request a change to the description")

    click_button("Save and mark as complete")

    expect(page).not_to have_content(
      "Description change requests must be closed or cancelled"
    )
  end

  it "lets the user request an additional document" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    click_link("Check and assess")
    click_link("Check description, documents and proposal details")

    form_group = form_group_with_legend(
      "Are the plans consistent with each other?"
    )

    within(form_group) { choose("No") }
    click_link("Request a new document")

    fill_in(
      "Please specify the new document type:",
      with: "New document type"
    )

    fill_in(
      "Please specify the reason you have requested this document?",
      with: "Reason for new document"
    )

    click_button("Send request")

    expect(page).to have_content("Alice Smith requested a new document")
    expect(page).to have_content("New document type")
    expect(page).to have_content("Reason: Reason for new document")
    expect(page).to have_content("Requested 15 September 2022 12:00")

    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Additional document requests must be closed or cancelled"
    )

    click_link("View and edit request")
    click_link("Cancel request")

    fill_in(
      "Explain to the applicant why this request is being cancelled",
      with: "Cancellation reason"
    )

    click_button("Confirm cancellation")
    visit(planning_application_assessment_tasks_path(planning_application))
    click_link("Check description, documents and proposal details")

    expect(page).to have_content("Cancelled 15 September 2022 12:00")

    click_button("Save and mark as complete")

    expect(page).not_to have_content(
      "Additional document requests must be closed or cancelled"
    )
  end

  context "when applicant has provided additional document" do
    before do
      create(
        :additional_document_validation_request,
        :with_documents,
        planning_application:
      )
    end

    it "lets the user navigate to the document" do
      click_link("Check and assess")
      click_link("Check description, documents and proposal details")
      click_link("View new document")
      expect(page).to have_content("File name: proposed-floorplan.png")
    end
  end

  it "lets the user request a red line boundary change" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    click_link("Check and assess")
    click_link("Check description, documents and proposal details")

    form_group = form_group_with_legend(
      "Is the red line on the site map correct for the site and proposed works?"
    )

    within(form_group) { choose("No") }
    click_link("Request a change to the red line boundary")

    find(".govuk-visually-hidden", visible: false).set(
      {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            properties: {},
            geometry: {
              type: "Polygon",
              coordinates: [
                [
                  [-0.054597, 51.537332],
                  [-0.054588, 51.537288],
                  [-0.054453, 51.537312],
                  [-0.054597, 51.537332]
                ]
              ]
            }
          }
        ]
      }.to_json
    )

    fill_in(
      "Explain to the applicant why changes are proposed to the red line boundary",
      with: "request reason"
    )

    click_button("Send request")

    expect(page).to have_content(
      "Validation request for red line boundary successfully created."
    )

    form_group = form_group_with_legend(
      "Is the red line on the site map correct for the site and proposed works?"
    )

    within(form_group) { expect(find_field("No")).to be_checked }
    expect(page).not_to have_link("Request a change to the red line boundary")
    expect(page).to have_content("Alice Smith proposed a new red line boundary")
    expect(page).to have_content("Reason: request reason")
    expect(page).to have_content("Proposed 15 September 2022 12:00")

    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Red line boundary change requests must be closed or cancelled"
    )

    click_link("View and edit request")
    click_link("Cancel request")

    fill_in(
      "Explain to the applicant why this request is being cancelled",
      with: "cancellation reason"
    )

    click_button("Confirm cancellation")
    click_link("Application")
    click_link("Check and assess")
    click_link("Check description, documents and proposal details")

    expect(page).to have_content("Cancelled 15 September 2022 12:00")

    click_button("Save and mark as complete")

    expect(page).not_to have_content(
      "Red line boundary change requests must be closed or cancelled"
    )
  end

  def form_group_with_legend(legend)
    find("legend", text: legend).find(:xpath, "..")
  end

  def task_list_item
    text = "Check description, documents and proposal details"
    find("span", text:).find(:xpath, "..")
  end
end
