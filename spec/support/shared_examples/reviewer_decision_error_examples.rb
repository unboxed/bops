# frozen_string_literal: true

RSpec.shared_examples 'reviewer decision error message' do
  scenario "shows the error message" do
    within("#awaiting_determination") do
      click_link planning_application.reference
    end

    expect(page).not_to have_link("Publish the recommendation")

    click_link "Review the recommendation"

    click_button "Save"

    within(".govuk-error-message") do
      expect(page).to have_content("Please select Yes or No")
    end

    click_link "Home"

    expect(page).not_to have_content ("Completed")
  end
end
