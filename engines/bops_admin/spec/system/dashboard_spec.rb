# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let(:local_authority) { create(:local_authority, :default) }

  before do
    sign_in(user)
  end

  context "when the user is an assessor" do
    let(:user) { create(:user, :assessor, local_authority:) }

    it "doesn't allow access to the dashboard" do
      visit "/admin/dashboard"

      expect(page).to have_current_path("/")
      expect(page).to have_content("You need to be an administrator to view the page '/admin/dashboard'")
    end
  end

  context "when the user is a reviewer" do
    let(:user) { create(:user, :reviewer, local_authority:) }

    it "doesn't allow access to the dashboard" do
      visit "/admin/dashboard"

      expect(page).to have_current_path("/")
      expect(page).to have_content("You need to be an administrator to view the page '/admin/dashboard'")
    end
  end

  context "when the user is an administrator" do
    let(:user) { create(:user, :administrator, local_authority:, name: "Anne Administrator") }

    it "shows the dashboard" do
      visit "/admin/dashboard"

      expect(page).to have_current_path("/admin/dashboard")
      expect(page).to have_content("Welcome Anne Administrator")
      expect(page).to have_link("Users", href: "/admin/users")
      expect(page).to have_link("Profile", href: "/admin/profile")
    end
  end
end
