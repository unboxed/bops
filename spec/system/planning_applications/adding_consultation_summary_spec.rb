# frozen_string_literal: true

require "rails_helper"

RSpec.describe "adding consultation summary" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority: default_local_authority)
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: default_local_authority
    )
  end

  it "lets user save draft, mark as complete, and edit" do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
    click_link("Check and assess")

    expect(list_item("Summary of consultation")).to have_content("Not started")

    click_link("Summary of consultation")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultees must be added")

    expect(page).to have_content(
      "Summary of consultation responses can't be blank"
    )

    click_button("Add consultee")

    expect(page).to have_content("Name can't be blank")
    expect(page).to have_content("Origin can't be blank")

    fill_in("Enter a new consultee", with: "Alice Smith")
    choose("Internal consultee")
    click_button("Add consultee")

    expect(page).to have_row_for("Alice Smith", with: "Internal")

    fill_in("Enter a new consultee", with: "Bella Jones")
    choose("External consultee")
    click_button("Add consultee")

    expect(page).to have_row_for("Bella Jones", with: "External")

    within(row_with_content("Bella Jones")) { click_button("Remove from list") }

    expect(page).not_to have_content("Bella Jones")

    click_button("Save and come back later")

    expect(page).to have_content("Consultation summary successfully added.")
    expect(list_item("Summary of consultation")).to have_content("In progress")

    click_link("Summary of consultation")
    fill_in("Summary of consultation responses", with: "Lorem ipsum")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultation summary successfully updated.")
    expect(list_item("Summary of consultation")).to have_content("Complete")

    click_link("Summary of consultation")

    expect(page).to have_row_for("Alice Smith", with: "Internal")
    expect(page).to have_content("Lorem ipsum")

    click_link("Edit consultation details")
    fill_in("Summary of consultation responses", with: "dolor sit amet")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultation summary successfully updated.")
  end
end
