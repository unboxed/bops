# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system, bops_config: true do
  let(:local_authority) { create(:local_authority, :default) }

  before do
    visit "/"
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Log in"
  end

  context "when the user is an assessor" do
    let(:user) { create(:user, :assessor, local_authority:) }

    it "doesn't allow access to the dashboard" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is a reviewer" do
    let(:user) { create(:user, :reviewer, local_authority:) }

    it "doesn't allow access to the dashboard" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is an administrator for a local authority" do
    let(:user) { create(:user, :administrator, local_authority:) }

    it "doesn't allow access to the dashboard" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is a global administrator" do
    let(:user) { create(:user, :global_administrator, otp_required_for_login: false, local_authority: nil, name: "Gordon Global Administrator") }

    it "shows the dashboard" do
      expect(page).to have_current_path("/dashboard")
      expect(page).to have_content("Welcome Gordon Global Administrator")
      expect(page).to have_link("Users", href: "/users")
    end
  end
end
