# frozen_string_literal: true

# Shared examples for check application details task.
# Calling specs must define: planning_application, user, task_page_path, task

RSpec.shared_examples "check application details form links" do
  it "shows link to request a description change when selecting No" do
    within_fieldset("Does the description match the development or use in the plans?") do
      choose "No"
    end

    expect(page).to have_link("Request a change to the description")
  end

  it "shows link to request an additional document when selecting No" do
    within_fieldset("Are the plans consistent with each other?") do
      choose "No"
    end
    expect(page).to have_link("Request a new document")
  end
end

RSpec.shared_examples "check application details requesting additional document" do
  it "lets the user request an additional document and returns to the task" do
    travel_to(Time.zone.local(2022, 9, 15, 12))
    visit("/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-application-details")

    within_fieldset("Are the plans consistent with each other?") do
      choose "No"
    end
    click_link "Request a new document"

    fill_in "Please specify the new document type:", with: "New document type"
    fill_in "Please specify the reason you have requested this document?", with: "Reason for new document"
    click_button "Send request"

    expect(page).to have_content("#{user.name} requested a new document")
    expect(page).to have_content("New document type")
    expect(page).to have_content("Reason: Reason for new document")
    expect(page).to have_content("Requested 15 September 2022 12:00")
  end
end

RSpec.shared_examples "check application details with existing additional document request" do
  it "shows the additional document request and lets the user view the document" do
    expect(page).to have_content("requested a new document")
    click_link "View new document"

    expect(page).to have_content("File name: proposed-floorplan.png")
  end
end
