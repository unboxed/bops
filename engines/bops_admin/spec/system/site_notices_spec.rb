# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site notices", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "allows the administrator to update the accessibility information for applicants" do
    expect(local_authority).to have_attributes(
      site_notice_logo: nil,
      site_notice_phone_number: nil,
      site_notice_email_address: nil,
      site_notice_show_assigned_officer: false
    )

    visit "/admin/profile"
    expect(page).to have_link("Manage site notices", href: "/admin/site_notices/edit")

    click_link "Manage site notices"
    expect(page).to have_selector("h1", text: "Manage site notice appearance")

    fill_in "Logo", with: "<svg></svg>"
    fill_in "Email address", with: "planning"

    click_button "Submit"

    expect(page).to have_content("Couldn't recognise the contents as a valid SVG file")
    expect(page).to have_content("Enter a valid email address for site notices")

    fill_in "Logo", with: <<~SVG
      <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="50" />
      </svg>
    SVG

    fill_in "Phone number", with: "020 7250 1250"
    fill_in "Email address", with: "planning@example.com"

    within_fieldset("Show assigned officer on the site notice?") do
      choose "Yes"
    end

    click_button "Submit"

    expect(page).to have_content("Site notice appearance successfully updated")

    expect(local_authority.reload).to have_attributes(
      site_notice_logo: %(<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">\n  <circle cx="50" cy="50" r="50" />\n</svg>\n),
      site_notice_phone_number: "020 7250 1250",
      site_notice_email_address: "planning@example.com",
      site_notice_show_assigned_officer: true
    )
  end
end
