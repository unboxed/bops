# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessibility", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "allows the administrator to update the accessibility information for applicants" do
    expect(local_authority).to have_attributes(
      accessibility_postal_address: nil, accessibility_phone_number: nil
    )

    visit "/admin/profile"
    expect(page).to have_link("Manage accessibility info", href: "/admin/accessibility/edit")

    click_link "Manage accessibility info"
    expect(page).to have_selector("h1", text: "Manage accessibility information")

    click_button "Submit"
    expect(page).to have_content("Enter a postal address for the applicants accessibility page")
    expect(page).to have_content("Enter a phone number for the applicants accessibility page")
    expect(page).to have_content("Enter an email address for the applicants accessibility page")

    fill_in "Postal address", with: "60-62 Commercial Street\nLondon\nE1 6LT"
    fill_in "Phone number", with: "020 7250 1250"
    fill_in "Email address", with: "planning@example.com"

    click_button "Submit"
    expect(page).to have_content("Accessibility information successfully updated")
    expect(page).to have_field("Postal address", with: "60-62 Commercial Street\r\nLondon\r\nE1 6LT")
    expect(page).to have_field("Phone number", with: "020 7250 1250")
    expect(page).to have_field("Email address", with: "planning@example.com")
  end
end
