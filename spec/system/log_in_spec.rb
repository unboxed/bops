# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home page renders correctly", type: :system do
  let!(:assessor) { create(:user, :assessor) }
  let!(:reviewer) { create(:user, :reviewer) }
  let!(:admin) { create(:user, :admin) }

  scenario "Home page redirects to login" do
    visit "/"
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  scenario "User can log in with valid credentials" do
    sign_in(assessor)
    expect(page).to have_text("Welcome")
  end

  scenario "User cannot log in with invalid credentials" do
    invalid_user = create(:user, :assessor, password: "xxxxxxxxxx")
    visit "/"
    fill_in("user[email]", with: invalid_user.email)
    fill_in("user[password]", with: invalid_user.password)
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  context "as an assessor" do
      before do
        sign_in(assessor)
      end

      scenario "Planning Officer can see name on welcome screen" do
        expect(page).to have_text(assessor.name)
      end

      scenario "Planning Officer has correct permission level" do
        expect(page).to have_text("Anyone who is logged in")
      end
    end

  context "as a reviewer" do
    before do
      sign_in(reviewer)
    end

    scenario "Planning Manager can see name on welcome screen" do
      expect(page).to have_text(reviewer.name)
    end

    scenario "Planning Manager has correct permission level" do
      expect(page).to have_text("logged in as a Planning Manager")
    end
  end

  context "as an admin" do
      before do
        sign_in(admin)
      end

      scenario "Admin can see name on welcome screen" do
        expect(page).to have_text(admin.name)
      end

      scenario "Admin has correct permission level" do
        expect(page).to have_text("logged in as an Admin")
      end
    end
end
