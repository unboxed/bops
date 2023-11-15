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
    visit planning_application_path(planning_application)
  end

  it "displays the planning application address and reference" do
    visit(
      new_planning_application_validation_description_change_validation_request_path(
        planning_application
      )
    )

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  it "lets user create and cancel request" do
    visit(planning_application_assessment_tasks_path(planning_application))
    click_button("Application information")
    click_link("Propose a change to the description")
    fill_in("Please suggest a new application description", with: "")
    click_button("Send")

    expect(page).to have_content("Proposed description can't be blank")

    fill_in("Please suggest a new application description", with: "description")
    click_button "Send"

    expect(page).to have_text("Description change request successfully sent.")

    expect(page).to have_current_path(
      planning_application_assessment_tasks_path(planning_application)
    )

    click_button("Application information")
    click_link("View requested change")
    click_button("Cancel this request")

    expect(page).to have_content(
      "Description change request successfully cancelled."
    )

    expect(page).to have_current_path(
      planning_application_assessment_tasks_path(planning_application)
    )
  end
end
