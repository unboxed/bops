# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Users", type: :system do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let(:last_email) { ActionMailer::Base.deliveries.last }
  let(:secure_password) { PasswordGenerator.call }
  let(:last_user) { User.last }
  let(:last_user_reset_token) { last_user.send_reset_password_instructions }

  before do
    sign_in(user)
    visit "/"
  end

  it "does not allow a user to update own role" do
    click_link "Users"

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Clark Kent")
      click_link("Edit user")
    end

    expect(page).to have_no_field("Role")
  end

  it "does not allow a user to update own role" do
    click_link "Users"

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Clark Kent")
      click_link("Edit user")
    end

    expect(page).to have_no_field("Role")
  end

  it "allows adding a new user" do
    click_link "Users"
    expect(page).to have_selector("h1", text: "Manage global admin users")

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

    click_button("Submit")
    expect(page).to have_content("User successfully created")

    within("#unconfirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("alice@example.com")
      expect(page).to have_content("01234 123 123")
      expect(page).to have_content("Email")
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
    expect(page).to have_current_path("/dashboard")
    expect(page).to have_content("Signed in successfully")
  end

  it "allows adding a new user without a mobile number" do
    click_link "Users"
    click_link "Add user"
    expect(page).to have_selector("h1", text: "Add a new user")

    fill_in("Name", with: "Alice Smith")
    fill_in("Email", with: "alice@example.com")

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
    expect(page).to have_current_path("/dashboard")
    expect(page).to have_content("Signed in successfully")
  end

  it "allows editing of an existing user" do
    create(:user, :global_administrator, name: "Wonder Woman", otp_delivery_method: :email, local_authority: nil)

    visit "/"
    click_link "Users"
    expect(page).to have_selector("h1", text: "Manage global admin users")

    within("#confirmed tbody tr:nth-child(2)") do
      expect(page).to have_content("Wonder Woman")
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

    click_button("Submit")
    expect(page).to have_content("User successfully updated")

    within("#confirmed tbody tr:nth-child(1)") do
      expect(page).to have_content("Belle Jones")
      expect(page).to have_content("belle@example.com")
      expect(page).to have_content("01234 456 456")
      expect(page).to have_content("SMS")
    end
  end

  context "when users are unconfirmed" do
    before do
      2.times do
        create(:user, :global_administrator, :unconfirmed, local_authority: nil)
      end
    end

    it "shows a warning" do
      visit "/users"

      expect(page).to have_content("2 users have not confirmed their email")
      expect(page).to have_content("Resend invites to unconfirmed users.")
    end
  end

  context "when there are a mix of confirmed and unconfirmed users", :capybara do
    before do
      create(:user, :global_administrator, local_authority: nil, name: "Dieter Waldbeck")
      create(:user, :global_administrator, :unconfirmed, local_authority: nil, name: "Andrea Khan")
      create(:user, :global_administrator, :unconfirmed, local_authority: nil, name: "Rosie Starr")
    end

    it "breaks them into two lists" do
      visit "/users"

      expect(page).to have_selector("h1", text: "Manage global admin users")
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
      visit "/users"
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Confirmed")

      click_link("Unconfirmed")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Unconfirmed")

      within("#unconfirmed tbody tr:nth-child(2)") do
        expect(page).to have_content("Rosie Starr")
        click_button("Resend invite")
      end

      expect(page).to have_content("User will receive a reminder email")
      expect(last_email.subject).to eq("Set password instructions")
      expect(last_email.body).to include("http://config.bops.services/users/password/edit?reset_password_token=")
    end
  end

  context "when there are deactivated users", :capybara do
    before do
      create(:user, :global_administrator, local_authority: nil, name: "Dieter Waldbeck")
      create(:user, :global_administrator, local_authority: nil, name: "Andrea Khan", deactivated_at: 1.day.ago)
    end

    it "lists the deactivated users" do
      click_link "Users"

      click_link "Deactivated"

      within("#deactivated table.govuk-table") do
        expect(page).to have_selector("tr:nth-child(1)", text: "Andrea Khan")
        # only testing for the date, not the time, to avoid a race condition if the minute ticks over
        expect(page).to have_selector("tr:nth-child(1)", text: "Deactivated at #{1.day.ago.to_date.to_fs}")
      end
    end

    it "allows reactivating the deactivated users" do
      click_link "Users"

      click_link "Deactivated"

      within("#deactivated table.govuk-table") do
        click_on "Edit user"
      end

      accept_confirm do
        click_on "Reactivate"
      end

      expect(page).to have_text("User successfully reactivated")
      within("#confirmed table.govuk-table") do
        expect(page).to have_selector("tr:nth-child(1)", text: "Andrea Khan")
      end
    end
  end

  context "when user account is deactivated", :capybara do
    let(:deactivated_user) { create(:user, :global_administrator, local_authority: nil, deactivated_at: 1.day.ago) }

    before do
      sign_out(user)
    end

    it "can't sign in" do
      click_link "Users"

      fill_in("user[email]", with: deactivated_user.email)
      fill_in("user[password]", with: deactivated_user.password)
      click_button("Log in")

      expect(page).to have_text("Invalid Email or password.")
      expect(page).not_to have_text("Signed in successfully.")
    end
  end
end
