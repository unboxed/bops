# frozen_string_literal: true

require "rails_helper"

RSpec.describe "updating constraints" do
  let(:local_authority) { create(:local_authority, :default) }

  let(:planning_application) do
    create(
      :planning_application,
      local_authority:,
      constraints: []
    )
  end

  let(:assessor) do
    create(:user, :assessor, local_authority:)
  end

  it "lets the user update the constraints" do
    sign_in(assessor)
    visit(planning_application_assessment_tasks_path(planning_application))
    click_button("Constraints")
    click_link("Update constraints")
    check("Conservation Area")
    click_button("Save")

    expect(page).to have_content("Constraints have been updated")

    expect(page).to have_current_path(
      planning_application_assessment_tasks_path(planning_application)
    )

    click_button("Constraints")

    expect(page).to have_content("Conservation Area")

    click_link("Application")
    click_button("Audit log")

    expect(page).to have_content("Constraint added")
  end
end
