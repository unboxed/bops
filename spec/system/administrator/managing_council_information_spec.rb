# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing council information profile" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
    visit "/administrator/local_authority"
  end

  it "allows the administrator to view council information profile" do
    expect(page).to have_content("Signatory")

    expect(page).to have_content("Job title")

    expect(page).to have_content("Contact address")

    expect(page).to have_content("Email")

    expect(page).to have_content("Feedback email")

    expect(page).to have_content("BOPS lead email")

    expect(page).to have_content("Press notice email")

    expect(page).to have_content("Notify API key")

    expect(page).to have_content("'Reply to' Notify ID")

    expect(page).to have_content("'Email to' Notify ID")
  end

  it "displays the correct hint text on the council information profile" do
    expect(page).to have_content("the person whose signature")

    expect(page).to have_content("job title of the person whose signature")

    expect(page).to have_content("the contact address that will appear on decision notices")

    expect(page).to have_content("email address that appears on decision notices.")

    expect(page).to have_content("deal with any queries about the BOPS service")

    expect(page).to have_content("person who will be responsible for managing")

    expect(page).to have_content("who will prepare press notices")

    expect(page).to have_content("ID number of the letter template you will use in Notify")

    expect(page).to have_content("API key used by the GOV.UK Notify service for sending emails")

    expect(page).to have_content("Find this in your Notify account.")
  end

  it "shows the council as active" do
    visit "/"
    expect(page).to have_content("Active")
  end

  it "allows the administrator to edit council information profile" do
    click_link("Edit profile")

    fill_in("Signatory", with: "Andrew Drey")

    fill_in("Job title", with: "Director")

    fill_in("Contact address", with: "ssssss")

    fill_in("Email", with: "email@buckinghamshire.gov.uk")

    fill_in("Feedback email", with: "feedback_email@buckinghamshire.gov.uk")

    fill_in("BOPS lead email", with: "manager_email@buckinghamshire.gov.uk")

    fill_in("Press notice email", with: "press_notice_email@buckinghamshire.gov.uk")

    fill_in("Notify API key", with: "ssssss")

    fill_in("'Reply to' Notify ID", with: "ssssss")

    fill_in("'Email to' Notify ID", with: "550e8400-e29b-41d4-a716-446655440000")

    click_button("Submit")

    expect(page).to have_content("Council information successfully updated")
  end
end
