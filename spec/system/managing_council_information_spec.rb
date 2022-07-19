# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing council information", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority: local_authority) }

  it "allows the administrator to manage the reviewer group email" do
    sign_in(user)
    visit(administrator_dashboard_path)
    row = find_all("tr").find { |tr| tr.has_content?("Manager group email") }
    within(row) { click_link("Edit") }
    fill_in("Manager group email", with: "qwerty")
    click_button("Submit")

    expect(page).to have_content("Reviewer group email is invalid")

    fill_in("Manager group email", with: "list@example.com")
    click_button("Submit")

    expect(page).to have_content("Council information successfully updated")
    row = find_all("tr").find { |tr| tr.has_content?("Manager group email") }
    expect(row).to have_content("list@example.com")
  end
end
