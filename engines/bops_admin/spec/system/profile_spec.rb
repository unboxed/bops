# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile", type: :system do
  let(:local_authority) { create(:local_authority, :default, :with_api_user) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "shows the council as active on the dashboard" do
    visit "/admin/dashboard"
    expect(page).to have_content("Active")
  end

  it "allows the administrator to view the council's profile" do
    visit "/admin/profile"

    expect(page).to have_content("Signatory")
    expect(page).to have_content("API key")
    expect(page).to have_content("Job title")
    expect(page).to have_content("Contact address")
    expect(page).to have_content("Email")
    expect(page).to have_content("Feedback email")
    expect(page).to have_content("Contact telephone")
    expect(page).to have_content("BOPS lead email")
    expect(page).to have_content("Press notice email")
    expect(page).to have_content("Notify API key")
    expect(page).to have_content("Reply-to email address ID")
    expect(page).to have_content("Document checklist")
  end

  it "shows the correct hint text for the council's profile" do
    visit "/admin/profile"

    expect(page).to have_content("This is the api key which can be used on swagger (opens in new tab) to generate more test planning application data.")
    expect(page).to have_link("swagger", href: "/api/v2/docs")

    expect(page).to have_content("the person whose signature")
    expect(page).to have_content("job title of the person whose signature")
    expect(page).to have_content("the contact address that will appear on decision notices")
    expect(page).to have_content("email address that appears on decision notices.")
    expect(page).to have_content("deal with any queries about the BOPS service")
    expect(page).to have_content("will appear on decision notices and other correspondence.")
    expect(page).to have_content("person who will be responsible for managing")
    expect(page).to have_content("who will prepare press notices")
    expect(page).to have_content("ID number of the letter template you will use in Notify")
    expect(page).to have_content("API key used by the GOV.UK Notify service for sending emails")
    expect(page).to have_content("Link to a document checklist that applicants use when submitting applications")
  end

  it "allows the administrator to edit council's profile" do
    visit "/admin/profile"
    expect(page).to have_link("Edit profile", href: "/admin/profile/edit")

    click_link("Edit profile")
    expect(page).to have_selector("h1", text: "Edit profile")

    fill_in("Signatory", with: "Andrew Drey")
    fill_in("Job title", with: "Director")
    fill_in("Contact address", with: "Planning, Buckinghamshire Council")
    fill_in("Email", with: "email@buckinghamshire.gov.uk")
    fill_in("Feedback email", with: "feedback_email@buckinghamshire.gov.uk")
    fill_in("Contact telephone (optional)", with: "0123456789")
    fill_in("BOPS lead email", with: "manager_email@buckinghamshire.gov.uk")
    fill_in("Press notice email", with: "press_notice_email@buckinghamshire.gov.uk")
    fill_in("Notify API key", with: "fake-fd74e59d-8939-4d28-bc1b-95b8a6c7d413")
    fill_in("Reply-to email address ID", with: "550e8400-e29b-41d4-a716-446655440000")
    fill_in("Document checklist", with: "https://www.buckinghamshire.gov.uk/planning-and-building-control/building-or-improving-your-property/how-to-prepare-a-valid-planning-application/")

    click_button("Submit")
    expect(page).to have_content("Council information successfully updated")
  end
end
