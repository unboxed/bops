# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in", type: :system do
  let(:assessor) { create :user, :assessor, name: "Lorrine Krajcik" }
  let(:reviewer) { create :user, :reviewer, name: "Harley Dicki" }

  it "ensure we can perform a healthcheck" do
    visit healthcheck_path

    expect(page.body).to have_content("OK")
  end

  it "Home page redirects to login" do
    visit root_path

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Your fast track applications")
  end

  it "User cannot log in with invalid credentials" do
    visit root_path

    fill_in("user[email]", with: reviewer.email)
    fill_in("user[password]", with: "invalid_password")
    click_button("Log in")

    expect(page).to have_text("Invalid Email or password.")
    expect(page).not_to have_text("Signed in successfully.")
  end

  context "users with valid credentials" do
    context "as an assessor" do
      before do
        sign_in assessor
        visit root_path
      end

      it "can see their name and role" do
        expect(page).to have_text("Lorrine Krajcik")
        expect(page).to have_text("Assessor")
      end
    end

    context "as a reviewer" do
      before do
        sign_in reviewer
        visit root_path
      end

      it "can see their name and role" do
        expect(page).to have_text("Harley Dicki")
        expect(page).to have_text("Reviewer")
      end
    end

    context "a user belonging to a given subdomain" do
      let!(:lambeth) { create :local_authority, subdomain: "lamb" }
      let!(:southwark) { create :local_authority, subdomain: "south" }
      let(:lambeth_assessor) { create :user, :assessor, name: "Lambertina Lamb", password: "Lambsrock18!", local_authority: lambeth }
      let(:southwark_assessor) { create :user, :assessor, name: "Southwarkina Sully", password: "Southwark4ever!", local_authority: southwark }

      before do
        @previous_host = Capybara.app_host
        host! "http://lamb.example.com"
      end

      after do
        host! "http://#{@previous_host}"
      end

      it "is prevented from logging in to a different subdomain" do
        visit root_path

        fill_in("user[email]", with: southwark_assessor.email)
        fill_in("user[password]", with: "Southwark4ever!")
        click_button("Log in")
        expect(page).to have_text("Email")
        expect(page).not_to have_text("Welcome")
      end

      it "is able to login to its allocated subdomain" do
        visit root_path

        fill_in("user[email]", with: lambeth_assessor.email)
        fill_in("user[password]", with: "Lambsrock18!")
        click_button("Log in")

        expect(page).to have_text("Signed in successfully.")
      end
    end
  end
end
