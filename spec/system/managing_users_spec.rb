# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing users" do
  let(:local_authority) { create(:local_authority, :default) }

  before do
    sign_in current_user
  end

  context "when current user is administrator" do
    let(:current_user) do
      create(
        :user,
        :administrator,
        name: "Carrie Taylor",
        local_authority:
      )
    end

    it "allows adding of new user" do
      password = secure_password

      visit "/administrator_dashboard"
      click_link("Add user")
      click_button("Submit")

      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Password can't be blank")

      fill_in("Email", with: "alice")
      fill_in("Mobile number", with: "not a number")
      click_button("Submit")

      expect(page).to have_content("Email is invalid")
      expect(page).to have_content("Mobile number is invalid")

      fill_in("Name", with: "Alice Smith")
      fill_in("Email", with: "alice@example.com")
      fill_in("Password", with: password)
      fill_in("Mobile number", with: "01234123123")
      select("Email", from: "Verification code delivery method")
      select("Assessor", from: "Role")
      click_button("Submit")

      expect(page).to have_content("User successfully created")
      row = row_with_content("Alice Smith")
      expect(row).to have_content("alice@example.com")
      expect(row).to have_content("01234 123 123")
      expect(row).to have_content("Email")
      expect(row).to have_content("Assessor")

      user = User.last
      user.confirm

      click_link("Log out")
      fill_in("Email", with: "alice@example.com")
      fill_in("Password", with: password)
      click_button("Log in")
      fill_in("Security code", with: User.last.current_otp)
      click_button("Enter code")

      expect(page).to have_current_path("/")
    end

    it "allows adding of new user without mobile number" do
      password = secure_password

      visit "/users/new"
      fill_in("Name", with: "Alice Smith")
      fill_in("Email", with: "alice@example.com")
      fill_in("Password", with: password)
      select("Assessor", from: "Role")
      click_button("Submit")

      expect(page).to have_content("User successfully created")

      user = User.last
      user.confirm

      click_link("Log out")
      fill_in("Email", with: "alice@example.com")
      fill_in("Password", with: password)
      click_button("Log in")
      fill_in("Mobile number", with: "01234123123")
      click_button("Send code")
      fill_in("Security code", with: User.last.current_otp)
      click_button("Enter code")

      expect(page).to have_current_path("/")
    end

    it "allows editing of existing user" do
      create(
        :user,
        :reviewer,
        name: "Bella Jones",
        local_authority:,
        otp_delivery_method: :email
      )

      visit "/administrator_dashboard"
      row = row_with_content("Bella Jones")
      within(row) { click_link("Edit") }
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
      row = row_with_content("Belle Jones")
      expect(row).to have_content("belle@example.com")
      expect(row).to have_content("01234 456 456")
      expect(row).to have_content("SMS")
      expect(row).to have_content("Assessor")
    end

    it "does not allow current user to update own role" do
      visit "/administrator_dashboard"
      row = row_with_content("Carrie Taylor")
      within(row) { click_link("Edit") }

      expect(page).not_to have_field("Role")
    end
  end
end
