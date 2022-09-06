# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assessment against legislation", type: :system do
  let(:local_authority) { create(:local_authority, :default) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: local_authority
    )
  end

  let(:assessor) { create :user, :assessor, local_authority: local_authority }

  before do
    sign_in(assessor)
    visit planning_application_path(planning_application)
    click_link("Check and assess")
  end

  it "warns the user about unsaved changes" do
    click_link("Add assessment area")
    click_link("Back")
    click_link("Add assessment area")
    choose("Part 1 - Development within the curtilage of a dwellinghouse")
    dismiss_confirm { click_link("Back") }
    click_button("Continue")
    click_link("Back")
    click_button("Continue")

    check(
      "Class A - enlargement, improvement or other alteration of a dwellinghouse"
    )

    dismiss_confirm { click_link("Back") }
    click_button("Add classes")

    expect(page).to have_content("Policy classes have been successfully added")

    click_link("Part 1, Class A")
    click_link("Back")
    click_link("Part 1, Class A")
    choose("policies_1a_complies")
    dismiss_confirm { click_link("Back") }
    click_button("Save assessments")

    expect(page).to have_content("Successfully updated policy class")
  end

  it "displays the class title" do
    click_link("Add assessment area")
    choose("Part 1 - Development within the curtilage of a dwellinghouse")
    click_button("Continue")

    check(
      "Class A - enlargement, improvement or other alteration of a dwellinghouse"
    )
    check(
      "Class B - additions etc to the roof of a dwellinghouse"
    )

    click_button("Add classes")

    click_link("Part 1, Class A")
    expect(page).to have_content("Class title - enlargement, improvement or other alteration of a dwellinghouse")
    within(".govuk-table caption") do
      expect(page).to have_content("Part 1, Class A - enlargement, improvement or other alteration of a dwellinghouse")
    end

    click_link("Back")
    click_link("Part 1, Class B")
    expect(page).to have_content("Class title - additions etc to the roof of a dwellinghouse")
    within(".govuk-table caption") do
      expect(page).to have_content("Part 1, Class B - additions etc to the roof of a dwellinghouse")
    end
  end
end
