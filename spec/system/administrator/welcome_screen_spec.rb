# frozen_string_literal: true

require "rails_helper"

RSpec.describe "welcome screen" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
    visit "/administrator/dashboard"
  end

  it "shows welcome message" do
    expect(page).to have_content("Welcome #{user.name}")

    expect(page).to have_link(
      "Users",
      href: "/administrator/users"
    )

    expect(page).to have_link(
      "Profile",
      href: "/administrator/local_authority"
    )
  end
end
