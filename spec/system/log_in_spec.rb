# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home page renders correctly", type: :system do
  scenario "Home page redirects to login" do
    visit "/"
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  scenario "User can log in with valid credentials" do
    assessor = create(:user, :assessor)
    visit "/"
    sign_in(assessor)
    expect(page).to have_text("Welcome")
  end

  scenario "User cannot log in with invalid credentials" do
    assessor = create(:user, :assessor, password: "xxxxxxxxxx")
    visit "/"
    fill_in("user[email]", with: assessor.email)
    fill_in("user[password]", with: assessor.password)
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  context "as an assessor" do
    before do
      @assessor = create(:user, :assessor)
    end

    scenario "Planning Officer can see name on welcome screen" do
      visit "/"
      sign_in(@assessor)
      expect(page).to have_text(@assessor.name)
    end

    scenario "Planning Officer has correct permission level" do
      visit "/"
      sign_in(@assessor)
      expect(page).to have_text("Anyone who is logged in")
    end
  end

  context "as a reviewer" do
    before do
      @reviewer = create(:user, :reviewer)
    end

    scenario "Planning Manager can see name on welcome screen" do
      visit "/"
      sign_in(@reviewer)
      expect(page).to have_text(@reviewer.name)
    end

    scenario "Planning Manager has correct permission level" do
      visit "/"
      sign_in(@reviewer)
      expect(page).to have_text("logged in as a Planning Manager")
    end
  end

  context "as an admin user" do
    before do
      @admin = create(:user, :admin)
    end

    scenario "Admin can see name on welcome screen" do
        visit "/"
        sign_in(@admin)
        expect(page).to have_text(@admin.name)
      end

    scenario "Admin has correct permission level" do
      visit "/"
      sign_in(@admin)
      expect(page).to have_text("logged in as an Admin")
    end
  end
end
