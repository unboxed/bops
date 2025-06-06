# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting time extension to a planning application", type: :system, capybara: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:api_user) { create(:api_user, :validation_requests_ro) }

  let(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  let(:reference) { planning_application.reference }

  before do
    travel_to Time.zone.local(2024, 1, 1)
    sign_in assessor
    visit "/planning_applications/#{reference}"
  end

  it "displays the planning application address and reference" do
    visit "/planning_applications/#{reference}/assessment/tasks"
    click_button("Application information")
    click_link("Request extension")

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(reference)
  end

  it "lets user create and cancel request" do
    visit "/planning_applications/#{reference}/assessment/tasks"
    expect(page).to have_selector("h1", text: "Assess the application")

    click_button("Application information")
    expect(page).to have_selector(:open_accordion, text: "Application information")

    click_link("Request extension")
    expect(page).to have_content(planning_application.full_address)

    fill_in "Day", with: "03"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2027"

    fill_in "Enter a reason for the request", with: "This is taking longer than I thought"

    click_button "Send request"
    expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
    expect(page).to have_text("Time extension request successfully sent.")

    click_link("Extension requested")
    expect(page).to have_content("Review time extension request")

    click_link("Cancel request")
    expect(page).to have_content("You requested an extension")

    fill_in "Explain to the applicant why this request is being cancelled", with: "We need more time"

    click_button "Confirm cancellation"
    expect(page).to have_current_path("/planning_applications/#{reference}")
    expect(page).to have_content("Time extension request successfully cancelled.")
  end

  it "displays the expected error message when there is a time extension request already open" do
    visit "/planning_applications/#{reference}/assessment/tasks"
    click_button("Application information")
    click_link("Request extension")

    expect(page).to have_content(planning_application.full_address)

    fill_in "Day", with: "03"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2020"
    click_button("Send")

    expect(page).to have_content("The proposed date must be after the planning application's current expiry date")
  end

  it "displays the expected error message when the time extension is earlier than the current expiry" do
    visit "/planning_applications/#{reference}/assessment/tasks"
    click_button("Application information")
    click_link("Request extension")

    expect(page).to have_content(planning_application.full_address)

    fill_in "Day", with: "03"
    fill_in "Month", with: "03"
    fill_in "Year", with: "2020"
    click_button("Send")

    expect(page).to have_content("must be later than existing expiry date")
  end

  it "displays the previously created time extension request on the edit page" do
    create(:time_extension_validation_request, :closed, planning_application: planning_application, reason: "Took too long")

    visit "/planning_applications/#{reference}/assessment/tasks"
    click_button("Application information")
    click_link("Request extension")

    expect(page).to have_content("Activity log")
    expect(page).to have_content("Sent")
  end

  it "displays the rejection reason when applicant rejects the request" do
    rejected_request = create(:time_extension_validation_request, :closed, approved: false, planning_application: planning_application, reason: "Took too long", rejection_reason: "I can't wait any longer")

    visit "/planning_applications/#{reference}/validation/validation_requests/#{rejected_request.id}"

    expect(page).to have_content("Rejected")
    expect(page).to have_content("I can't wait any longer")
  end
end
