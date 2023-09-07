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

  before do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
    click_link("Check and assess")
  end

  it "lets user save draft, mark as complete, and edit" do
    expect(list_item("Summary of consultation")).to have_content("Not started")

    click_link("Summary of consultation")
    click_button("Save and mark as complete")

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
    expect(list_item("Summary of consultation")).to have_content("Completed")

    click_link("Summary of consultation")

    expect(page).to have_row_for("Alice Smith", with: "Internal")
    expect(page).to have_content("Lorem ipsum")

    click_link("Edit consultation details")
    fill_in("Summary of consultation responses", with: "dolor sit amet")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultation summary successfully updated.")
  end

  context "when setting consultee responses" do
    let!(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        local_authority: default_local_authority
      )
    end

    it "allows adding details of consultee responses" do
      click_link("Summary of consultation")
      fill_in("Enter a new consultee", with: "Alice Smith")
      choose("Internal consultee")
      click_button("Add consultee")

      expect(page).to have_content("Edit response")

      click_link("Edit response")
      fill_in("Response", with: "test 123")
      click_button("Update response")
      click_button("Save and come back later")
      expect(page).to have_content("Consultation summary successfully added.")

      click_link("Summary of consultation")
      fill_in("Enter a new consultee", with: "Bob Smith")
      choose("External consultee")
      click_button("Add consultee")

      expect(page).to have_content("Edit response")

      within(".govuk-table__row:nth-child(2)") do
        click_link("Edit response")
      end
      fill_in("Response", with: "test 234")
      click_button("Update response")
      click_button("Save and come back later")
      expect(page).to have_content("Consultation summary successfully updated.")

      expect(planning_application.consultees.length).to eq(2)
      expect(planning_application.consultees.first.name).to eq("Alice Smith")
      expect(planning_application.consultees.first.response).to eq("test 123")
      expect(planning_application.consultees.last.name).to eq("Bob Smith")
      expect(planning_application.consultees.last.response).to eq("test 234")
    end
  end
end
