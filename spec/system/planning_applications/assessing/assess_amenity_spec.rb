# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assessing amenity" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority: default_local_authority)
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :prior_approval,
      local_authority: default_local_authority
    )
  end

  it "lets user save draft, mark as complete, and edit" do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
    click_link("Check and assess")

    expect(list_item("Amenity")).to have_content("Not started")

    click_link("Amenity")
    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Entry can't be blank"
    )

    fill_in("assessment_detail[entry]", with: "The noise would be too loud")

    click_button("Save and come back later")

    expect(page).to have_content("Amenity assessment was successfully created.")
    expect(list_item("Amenity")).to have_content("In progress")

    click_link("Amenity")
    fill_in("assessment_detail[entry]", with: "Lorem ipsum")
    click_button("Save and mark as complete")

    expect(page).to have_content("Amenity assessment was successfully updated.")
    expect(list_item("Amenity")).to have_content("Completed")

    click_link("Amenity")

    expect(page).to have_content("Lorem ipsum")

    click_link("Edit amenity assessment")
    fill_in("assessment_detail[entry]", with: "dolor sit amet")
    click_button("Save and mark as complete")

    expect(page).to have_content("Amenity assessment was successfully updated.")
  end
end
