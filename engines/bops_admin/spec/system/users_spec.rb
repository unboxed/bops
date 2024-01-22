# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:, name: "Carrie Taylor") }
  let(:last_email) { ActionMailer::Base.deliveries.last }
  let(:secure_password) { PasswordGenerator.call }
  let(:last_user) { User.last }
  let(:last_user_reset_token) { last_user.send_reset_password_instructions }

  before do
    sign_in(user)
  end

  it "does not allow a user to update own role" do
    visit "/admin/users"

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Carrie Taylor")
      click_link("Edit user")
    end

    expect(page).to have_no_field("Role")
  end

  it "allows adding a new user" do
    visit "/admin/users"
    expect(page).to have_selector("h1", text: "Manage users")

    click_link("Add user")
    expect(page).to have_selector("h1", text: "Add a new user")

    click_button("Submit")
    expect(page).to have_content("Email can't be blank")

    fill_in("Email", with: "alice")
    fill_in("Mobile number", with: "not a number")

    click_button("Submit")
    expect(page).to have_content("Email is invalid")
    expect(page).to have_content("Mobile number is invalid")

    fill_in("Name", with: "Alice Smith")
    fill_in("Email", with: "alice@example.com")
    fill_in("Mobile number", with: "01234123123")
    select("Email", from: "Verification code delivery method")
    select("Assessor", from: "Role")

    click_button("Submit")
    expect(page).to have_content("User successfully created")

    within("#unconfirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("alice@example.com")
      expect(page).to have_content("01234 123 123")
      expect(page).to have_content("Email")
      expect(page).to have_content("Assessor")
    end

    click_link("Log out")
    expect(page).to have_current_path("/users/sign_in")

    visit "/users/password/edit?reset_password_token=#{last_user_reset_token}"
    expect(page).to have_selector("h1", text: "Create your password")

    fill_in("New password", with: secure_password)
    fill_in("Confirm new password", with: secure_password)

    click_button("Change password")
    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Your password has been changed successfully")

    fill_in("Email", with: "alice@example.com")
    fill_in("Password", with: secure_password)

    click_button("Log in")
    expect(page).to have_content("Enter the code you have received by email")

    fill_in("Security code", with: last_user.current_otp)

    click_button("Enter code")
    expect(page).to have_current_path("/")
    expect(page).to have_content("Signed in successfully")
  end

  it "allows adding a new user without a mobile number" do
    visit "/admin/users/new"
    expect(page).to have_selector("h1", text: "Add a new user")

    fill_in("Name", with: "Alice Smith")
    fill_in("Email", with: "alice@example.com")
    select("Assessor", from: "Role")

    click_button("Submit")
    expect(page).to have_content("User successfully created")

    click_link("Log out")
    expect(page).to have_current_path("/users/sign_in")

    visit "/users/password/edit?reset_password_token=#{last_user_reset_token}"
    expect(page).to have_selector("h1", text: "Create your password")

    fill_in("New password", with: secure_password)
    fill_in("Confirm new password", with: secure_password)

    click_button("Change password")
    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Your password has been changed successfully")

    fill_in("Email", with: "alice@example.com")
    fill_in("Password", with: secure_password)

    click_button("Log in")
    expect(page).to have_selector("h1", text: "Enter your phone number")

    fill_in("Mobile number", with: "01234123123")

    click_button("Send code")
    expect(page).to have_selector("h1", text: "Enter the code you have received by text message")

    fill_in("Security code", with: last_user.current_otp)

    click_button("Enter code")
    expect(page).to have_current_path("/")
    expect(page).to have_content("Signed in successfully")
  end

  it "allows editing of an existing user" do
    create(:user, :reviewer, local_authority:, name: "Bella Jones", otp_delivery_method: :email)

    visit "/admin/users"
    expect(page).to have_selector("h1", text: "Manage users")

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Bella Jones")
      click_link("Edit user")
    end

    expect(page).to have_selector("h1", text: "Edit user")

    fill_in("Email", with: "")

    click_button("Submit")
    expect(page).to have_content("Email can't be blank")

    fill_in("Email", with: "bella")
    fill_in("Mobile number", with: "not a number")

    click_button("Submit")
    expect(page).to have_content("Email is invalid")
    expect(page).to have_content("Mobile number is invalid")

    fill_in("Name", with: "Belle Jones")
    fill_in("Email", with: "belle@example.com")
    fill_in("Mobile number", with: "01234456456")
    select("SMS", from: "Verification code delivery method")
    select("Assessor", from: "Role")

    click_button("Submit")
    expect(page).to have_content("User successfully updated")

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Belle Jones")
      expect(page).to have_content("belle@example.com")
      expect(page).to have_content("01234 456 456")
      expect(page).to have_content("SMS")
      expect(page).to have_content("Assessor")
    end
  end

  context "when users are unconfirmed" do
    before do
      2.times do
        create(:user, :assessor, :unconfirmed, local_authority:)
      end
    end

    it "shows a warning" do
      visit "/admin/users"

      expect(page).to have_content("2 users have not confirmed their email")
      expect(page).to have_content("Resend invites to unconfirmed users to add them to your team.")
    end
  end

  context "when there are a mix of confirmed and unconfirmed users" do
    before do
      create(:user, :reviewer, local_authority:, name: "Dieter Waldbeck")
      create(:user, :assessor, :unconfirmed, local_authority:, name: "Andrea Khan")
      create(:user, :reviewer, :unconfirmed, local_authority:, name: "Rosie Starr")
    end

    it "breaks them into two lists" do
      visit "/admin/users"

      expect(page).to have_selector("h1", text: "Manage users")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Confirmed")
      expect(page).to have_link("Confirmed", href: "#confirmed")
      expect(page).to have_link("Unconfirmed", href: "#unconfirmed")

      within("#confirmed table.govuk-table") do
        expect(page).to have_selector("tr:nth-child(2)", text: "Dieter Waldbeck")
      end

      click_link("Unconfirmed")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Unconfirmed")

      within("#unconfirmed table.govuk-table") do
        expect(page).to have_selector("tr:nth-child(1)", text: "Andrea Khan")
        expect(page).to have_selector("tr:nth-child(2)", text: "Rosie Starr")
      end
    end

    it "allows resending an invite from the index page" do
      visit "/admin/users"
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Confirmed")

      click_link("Unconfirmed")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Unconfirmed")

      within("#unconfirmed tbody tr:nth-child(2)") do
        expect(page).to have_content("Rosie Starr")
        click_link("Resend invite")
      end

      expect(page).to have_content("User will receive a reminder email")
      expect(last_email.subject).to eq("Set password instructions")
      expect(last_email.body).to include("Welcome to the Back-office Planning System")
    end
  end
end
