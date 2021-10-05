# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: @default_local_authority,
                                                constraints: ["Conservation Area"]
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_button "Constraints"
  end

  context "Editing constraints" do
    it "can add and change constraints" do
      click_link("Update")

      check("Listed building")
      check("Broads")
      check("Flood zone 3")
      uncheck("Conservation Area")

      click_button("Save")

      click_button("Constraints")

      expect(page).to have_content("Listed building")
      expect(page).to have_content("Broads")
      expect(page).to have_content("Flood zone 3")
      expect(page).to have_no_content("Conservation Area")

      click_link("Update")

      expect(page).to have_field("Broads", checked: true)
      expect(page).to have_field("Flood zone 3", checked: true)
      expect(page).to have_field("Conservation Area", checked: false)
      expect(page).to have_field("Safety hazard area", checked: false)
    end

    it "can remove all constraints" do
      click_link("Update")

      uncheck("Conservation Area")

      page.all(".govuk-checkboxes__input").each do |checkbox|
        expect(checkbox).not_to be_checked
      end
    end

    it "correctly displays constraint not in the dictionary submitted via the input field" do
      click_link "Update"

      fill_in "Local constraints", with: "Bats live here"

      click_button("Save")

      click_button("Constraints")

      expect(page).to have_content("Bats live here")
      click_link("Update")

      expect(page).to have_field("Bats live here", checked: true)
    end

    it "creates an audit record when a constraint is added or removed" do
      click_link "Update"

      check("Flood zone 3")
      uncheck("Conservation Area")
      fill_in "Local constraints", with: "Batcave of national significance"

      click_button("Save")
      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Constraint added")
      expect(page).to have_text("Flood zone 3")

      expect(page).to have_text("Constraint removed")
      expect(page).to have_text("Conservation Area")

      expect(page).to have_text("Constraint added")
      expect(page).to have_text("Batcave of national significance")
    end

    it "allows for the constraints page to be saved with no changes to constraints" do
      click_link "Update"
      click_button("Save")

      expect(page).to have_text("Constraints have been updated")
    end
  end

  context "for planning application that has been determined" do
    let!(:planning_application) do
      create :planning_application, :determined, local_authority: @default_local_authority
    end

    it "prevents updating constraints" do
      click_button("Constraints")

      expect(page).not_to have_link "Update"
    end
  end

  context "for planning application that is awaiting determination" do
    let!(:planning_application) do
      create :planning_application, :awaiting_determination, local_authority: @default_local_authority
    end

    it "prevents updating constraints" do
      click_button("Constraints")

      expect(page).not_to have_link "Update"
    end
  end
end
