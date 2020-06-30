# frozen_string_literal: true

RSpec.shared_examples 'assessor decision error message' do
  scenario "shows the error message" do
    within("#in_assessment") do
      click_link "19/AP/1880"
    end

    expect(page).not_to have_link("Submit the recommendation")

    click_link "Assess the proposal"

    click_button "Save"

    within(".govuk-error-message") do
      expect(page).to have_content("Please select Yes or No")
    end

    click_link "Home"

    expect(page).not_to have_css(".app-task-list__task-completed")
  end
end
