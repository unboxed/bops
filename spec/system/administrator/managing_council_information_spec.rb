# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing council information" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
    visit "/administrator/local_authority"
  end

  it "allows the administrator to manage the reviewer group email" do
    row = row_with_content("Manager group email")
    within(row) { click_link("Edit") }
    fill_in("Manager group email", with: "qwerty")
    click_button("Submit")

    expect(page).to have_content("Reviewer group email is invalid")

    fill_in("Manager group email", with: "list@example.com")
    click_button("Submit")

    expect(page).to have_content("Council information successfully updated")

    expect(page).to have_row_for(
      "Manager group email",
      with: "list@example.com"
    )
  end

  it "allows the administrator to manage the press notice email" do
    row = row_with_content("Press notice email")
    within(row) { click_link("Edit") }
    fill_in("Press notice email", with: "ssssss")
    click_button("Submit")

    expect(page).to have_content("Press notice email is invalid")

    fill_in("Press notice email", with: "press_notice@example.com")
    click_button("Submit")

    expect(page).to have_content("Council information successfully updated")

    expect(page).to have_row_for(
      "Press notice email",
      with: "press_notice@example.com"
    )
  end
end
