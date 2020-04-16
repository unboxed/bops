# frozen_string_literal: true

RSpec.feature "Home page renders correctly", type: :feature do
  scenario "Home page redirects to login" do
    visit "/"
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  scenario "Home page header is correct" do
    visit "/"
    expect(page).to have_text("Back-Office Planning System")
  end
end
