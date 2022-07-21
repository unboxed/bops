# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing council information", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority: local_authority) }

  it "allows the administrator to manage the reviewer group email" do
    sign_in(user)
    visit(administrator_dashboard_path)
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
end
