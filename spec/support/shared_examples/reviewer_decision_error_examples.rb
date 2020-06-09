# frozen_string_literal: true

RSpec.shared_examples 'reviewer decision error message' do
  scenario "shows the error message" do
    within("#awaiting_determination") do
      click_link "19/AP/1880"
    end

    expect(page).not_to have_link("Publish and send decision notice")

    click_link "Review permitted development policy requirements"

    click_button "Save"

    within(".govuk-error-message") do
      expect(page).to have_content("Please select Yes or No")
    end

    click_link "Home"

    expect(page).not_to have_css(".app-task-list__task-completed")
  end
end
