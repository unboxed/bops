# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policies" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  context "when clicking 'Policy' in the primary navigation" do
    it "redirects to 'Policy areas'" do
      visit "/"
      expect(page).to have_link("Policy", href: "/admin/policy")

      click_link "Policy"
      expect(page).to have_current_path("/admin/policy/areas")
      expect(page).to have_selector("h1", text: "Manage policy areas")
    end
  end
end
