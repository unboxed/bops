# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sign in", type: :system do
  let(:admin) { create(:user, :admin) }

  scenario "Home page redirects to login" do
    visit "/"
    expect(page).to have_text("Email")
    expect(page).not_to have_text("Your fast track applications")
  end

  scenario "User cannot log in with invalid credentials" do
    visit "/"
    fill_in("user[email]", with: admin.email)
    fill_in("user[password]", with: "invalid_password")
    click_button('Log in')

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  context "users with valid credentials" do
    context "as an assessor" do
      let(:assessor) { create(:user, :assessor) }
      before do
        sign_in(assessor)
        visit "/"
      end

      scenario "can see their name and role" do
        expect(page).to have_text(assessor.name)
        expect(page).to have_text(assessor.role.capitalize)
      end
    end

    context "as a reviewer" do
      let(:reviewer) { create(:user, :reviewer) }
      before do
        sign_in(reviewer)
        visit "/"
      end

      scenario "can see their name and role" do
        expect(page).to have_text(reviewer.name)
        expect(page).to have_text(reviewer.role.capitalize)
      end
    end

    context "as an admin" do
      before do
        sign_in(admin)
        visit "/"
      end

      scenario "see can see their name and role" do
        expect(page).to have_text(admin.name)
        expect(page).to have_text(admin.role.capitalize)
      end
    end
  end
end
