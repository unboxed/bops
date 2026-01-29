# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Local authority users", type: :system do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:last_email) { ActionMailer::Base.deliveries.last }
  let(:last_user) { User.last }

  before do
    sign_in(user)
  end

  it "shows the manage users button on the local authority page" do
    visit "/local_authorities/#{local_authority.subdomain}"

    expect(page).to have_link("Manage users", href: "/local_authorities/#{local_authority.subdomain}/users")
  end

  it "displays the users index page with tabs" do
    create(:user, :assessor, local_authority:, name: "Alice Assessor")
    create(:user, :reviewer, local_authority:, name: "Bob Reviewer")

    visit "/local_authorities/#{local_authority.subdomain}/users"

    expect(page).to have_selector("h1", text: "Manage users for #{local_authority.short_name}")
    expect(page).to have_link("Confirmed", href: "#confirmed")
    expect(page).to have_link("Unconfirmed", href: "#unconfirmed")
    expect(page).to have_link("Deactivated", href: "#deactivated")

    within("#confirmed") do
      expect(page).to have_content("Alice Assessor")
      expect(page).to have_content("Bob Reviewer")
    end
  end

  it "allows adding a new user with role selection" do
    visit "/local_authorities/#{local_authority.subdomain}/users"

    click_link("Add user")
    expect(page).to have_selector("h1", text: "Add a new user")

    click_button("Submit")
    expect(page).to have_content("Email can't be blank")

    fill_in("Name", with: "Alice Smith")
    fill_in("Email", with: "alice@example.com")
    fill_in("Mobile number", with: "01234123123")
    select("Email", from: "Verification code delivery method")
    select("Assessor", from: "Role")

    click_button("Submit")
    expect(page).to have_content("User successfully created")

    within("#unconfirmed") do
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("alice@example.com")
      expect(page).to have_content("Assessor")
    end
  end

  it "allows editing an existing user" do
    create(:user, :assessor, local_authority:, name: "Bella Jones", otp_delivery_method: :email)

    visit "/local_authorities/#{local_authority.subdomain}/users"

    within("#confirmed") do
      click_link("Edit user")
    end

    expect(page).to have_selector("h1", text: "Edit user")

    fill_in("Name", with: "Belle Jones")
    fill_in("Email", with: "belle@example.com")
    select("Reviewer", from: "Role")

    click_button("Submit")
    expect(page).to have_content("User successfully updated")

    within("#confirmed") do
      expect(page).to have_content("Belle Jones")
      expect(page).to have_content("belle@example.com")
      expect(page).to have_content("Reviewer")
    end
  end

  it "does not allow assigning the global_administrator role" do
    visit "/local_authorities/#{local_authority.subdomain}/users/new"

    expect(page).to have_select("Role", options: ["Assessor", "Reviewer", "Administrator"])
    expect(page).not_to have_select("Role", with_options: ["Global administrator"])
  end

  it "only shows users belonging to the local authority" do
    other_authority = create(:local_authority, :southwark)
    create(:user, :assessor, local_authority:, name: "Local User")
    create(:user, :assessor, local_authority: other_authority, name: "Other User")

    visit "/local_authorities/#{local_authority.subdomain}/users"

    within("#confirmed") do
      expect(page).to have_content("Local User")
      expect(page).not_to have_content("Other User")
    end
  end

  it "returns not found when accessing a user from a different local authority" do
    other_authority = create(:local_authority, :southwark)
    other_user = create(:user, :assessor, local_authority: other_authority, name: "Other User")

    expect {
      visit "/local_authorities/#{local_authority.subdomain}/users/#{other_user.id}/edit"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "returns not found for a non-existent local authority" do
    expect {
      visit "/local_authorities/nonexistent/users"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "when users are unconfirmed" do
    before do
      2.times do
        create(:user, :assessor, :unconfirmed, local_authority:)
      end
    end

    it "shows a warning" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      expect(page).to have_content("2 users have not confirmed their email")
      expect(page).to have_content("Resend invites to unconfirmed users.")
    end
  end

  context "when there are a mix of confirmed and unconfirmed users", :capybara do
    before do
      create(:user, :assessor, local_authority:, name: "Dieter Waldbeck")
      create(:user, :reviewer, :unconfirmed, local_authority:, name: "Andrea Khan")
      create(:user, :assessor, :unconfirmed, local_authority:, name: "Rosie Starr")
    end

    it "breaks them into two lists" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      expect(page).to have_selector("h1", text: "Manage users for #{local_authority.short_name}")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Confirmed")

      within("#confirmed") do
        expect(page).to have_content("Dieter Waldbeck")
      end

      click_link("Unconfirmed")
      expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Unconfirmed")

      within("#unconfirmed") do
        expect(page).to have_content("Andrea Khan")
        expect(page).to have_content("Rosie Starr")
      end
    end

    it "allows resending an invite from the index page" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      click_link("Unconfirmed")

      within("#unconfirmed") do
        first(:button, "Resend invite").click
      end

      expect(page).to have_content("User will receive a reminder email")
    end
  end

  context "when there are deactivated users", :capybara do
    before do
      create(:user, :assessor, local_authority:, name: "Dieter Waldbeck")
      create(:user, :reviewer, local_authority:, name: "Andrea Khan", deactivated_at: 1.day.ago)
    end

    it "lists the deactivated users" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      click_link "Deactivated"

      within("#deactivated") do
        expect(page).to have_content("Andrea Khan")
        expect(page).to have_content("Deactivated at #{1.day.ago.to_date.to_fs}")
      end
    end

    it "allows reactivating the deactivated users" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      click_link "Deactivated"

      within("#deactivated") do
        click_on "Edit user"
      end

      accept_confirm do
        click_on "Reactivate"
      end

      expect(page).to have_text("User successfully reactivated")

      within("#confirmed") do
        expect(page).to have_content("Andrea Khan")
      end
    end
  end

  context "when deactivating a user", :capybara do
    before do
      create(:user, :assessor, local_authority:, name: "Charlie Brown")
    end

    it "allows deactivating a user" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      within("#confirmed") do
        click_link("Edit user")
      end

      accept_confirm do
        click_on "Deactivate"
      end

      expect(page).to have_text("User successfully deactivated")

      click_link "Deactivated"

      within("#deactivated") do
        expect(page).to have_content("Charlie Brown")
      end
    end
  end
end
