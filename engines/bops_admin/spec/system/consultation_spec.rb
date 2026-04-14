# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "allows the administrator to update the consultation information for neighbours" do
    expect(local_authority).to have_attributes(consultation_postal_address: nil)

    visit "/admin/profile"
    expect(page).to have_link("Manage consultation info", href: "/admin/consultation/edit")

    click_link "Manage consultation info"
    expect(page).to have_selector("h1", text: "Manage consultation information")

    click_button "Submit"
    expect(page).to have_content("Enter a postal address for neighbours to send comments to")

    fill_in "Postal address", with: "60-62 Commercial Street\nLondon\nE1 6LT"

    click_button "Submit"
    expect(page).to have_content("Consultation information successfully updated")
    expect(page).to have_field("Postal address", with: "60-62 Commercial Street\r\nLondon\r\nE1 6LT")
  end
end
