# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  let!(:api_user) { create(:api_user, name: "Api Wizard") }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
  end

  it "displays the planning application address and reference" do
    visit "/planning_applications/#{planning_application.id}/validation/description_change_validation_requests/new"

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  it "lets user create and cancel request" do
    visit "/planning_applications/#{planning_application.id}/assessment/tasks"
    click_button("Application information")
    click_link("Propose a change to the description")
    fill_in("Please suggest a new application description", with: "")
    click_button("Send")

    expect(page).to have_content("Proposed description can't be blank")

    fill_in("Please suggest a new application description", with: "description")
    click_button "Send"

    expect(page).to have_text("Description change request successfully sent.")

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.id}/assessment/tasks"
    )

    click_button("Application information")
    click_link("View requested change")
    click_button("Cancel this request")

    expect(page).to have_content(
      "Description change request successfully cancelled."
    )

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.id}/assessment/tasks"
    )
  end
end
