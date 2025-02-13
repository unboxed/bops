# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Sidekiq", type: :system do
  let(:local_authority) { create(:local_authority, :default) }

  before do
    visit "/sidekiq"
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Log in"
  end

  context "when the user is an assessor" do
    let(:user) { create(:user, :assessor, local_authority:) }

    it "doesn't allow access to the Sidekiq control panel" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is a reviewer" do
    let(:user) { create(:user, :reviewer, local_authority:) }

    it "doesn't allow access to the Sidekiq control panel" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is an administrator for a local authority" do
    let(:user) { create(:user, :administrator, local_authority:) }

    it "doesn't allow access to the Sidekiq control panel" do
      expect(page).to have_current_path("/users/sign_in")
      expect(page).to have_content("Invalid Email or password.")
    end
  end

  context "when the user is a global administrator" do
    let(:user) { create(:user, :global_administrator, otp_required_for_login: false, local_authority: nil, name: "Gordon Global Administrator") }

    it "shows the Sidekiq control panel" do
      expect(page).to have_current_path("/sidekiq/")
      expect(page).to have_content("Sidekiq")
      expect(page).to have_link("Metrics", href: "/sidekiq/metrics")
    end
  end
end
