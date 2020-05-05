# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sign in", type: :system do
  let(:admin) { create(:user, :admin) }

  scenario "ensure we can perform a healthcheck" do
    visit healthcheck_path

    expect(page.body).to have_content("OK")
  end

  scenario "Home page redirects to login" do
    visit root_path

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Your fast track applications")
  end

  scenario "User cannot log in with invalid credentials" do
    visit root_path

    fill_in("user[email]", with: admin.email)
    fill_in("user[password]", with: "invalid_password")
    click_button('Log in')

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Welcome")
  end

  context "users with valid credentials" do
    context "as an assessor" do
      before do
        sign_in users(:assessor)
        visit root_path
      end

      scenario "can see their name and role" do
        expect(page).to have_text("Lorrine Krajcik")
        expect(page).to have_text("Assessor")
      end
    end

    context "as a reviewer" do
      before do
        sign_in users(:reviewer)
        visit root_path
      end

      scenario "can see their name and role" do
        expect(page).to have_text("Harley Dicki")
        expect(page).to have_text("Reviewer")
      end
    end

    context "as an admin" do
      before do
        sign_in users(:admin)
        visit root_path
      end

      scenario "see can see their name and role" do
        expect(page).to have_text("Adrian Schimmel")
        expect(page).to have_text("Admin")
      end
    end
  end
end
