# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing users", type: :system do
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
        local_authority: local_authority
      )
    end

    it "allows adding of new user" do
      visit users_path
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
      fill_in("Password", with: "password")
      fill_in("Mobile number", with: "01234123123")
      select("Assessor", from: "Role")
      click_button("Submit")

      expect(page).to have_content("User successfully created")
      row = page.find_all("tr").find { |tr| tr.has_content?("Alice Smith") }
      expect(row).to have_content("alice@example.com")
      expect(row).to have_content("01234 123 123")
      expect(row).to have_content("Assessor")
    end

    it "allows editing of existing user" do
      create(
        :user,
        :reviewer,
        name: "Bella Jones",
        local_authority: local_authority
      )

      visit users_path
      row = page.find_all("tr").find { |tr| tr.has_content?("Bella Jones") }
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
      select("Assessor", from: "Role")
      click_button("Submit")

      expect(page).to have_content("User successfully updated")
      row = page.find_all("tr").find { |tr| tr.has_content?("Belle Jones") }
      expect(row).to have_content("belle@example.com")
      expect(row).to have_content("01234 456 456")
      expect(row).to have_content("Assessor")
    end

    it "does not allow current user to update own role" do
      visit users_path
      row = page.find_all("tr").find { |tr| tr.has_content?("Carrie Taylor") }
      within(row) { click_link("Edit") }

      expect(page).not_to have_field("Role")
    end
  end

  context "when current user is assessor" do
    let(:current_user) do
      create(:user, :assessor, local_authority: local_authority)
    end

    it "does not allow access to dashboard" do
      visit users_path
      expect(page).to have_current_path(root_path)
    end
  end

  context "when current user is reviewer" do
    let(:current_user) do
      create(:user, :reviewer, local_authority: local_authority)
    end

    it "does not allow access to dashboard" do
      visit users_path
      expect(page).to have_current_path(root_path)
    end
  end
end
