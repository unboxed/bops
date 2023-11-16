# frozen_string_literal: true

require "rails_helper"

RSpec.describe "administrator dashboard" do
  let(:local_authority) { create(:local_authority, :default) }

  context "when user is administrator" do
    let(:user) do
      create(:user, :administrator, local_authority:)
    end

    it "allows access to dashboard" do
      sign_in(user)
      visit(administrator_dashboard_path)
      expect(page).to have_current_path("/administrator_dashboard")
    end
  end

  context "when user is assessor" do
    let(:user) do
      create(:user, :assessor, local_authority:)
    end

    it "does not allow access to dashboard" do
      sign_in(user)
      visit(administrator_dashboard_path)
      expect(page).to have_current_path("/")
    end
  end

  context "when user is reviewer" do
    let(:user) do
      create(:user, :reviewer, local_authority:)
    end

    it "does not allow access to dashboard" do
      sign_in(user)
      visit(administrator_dashboard_path)
      expect(page).to have_current_path("/")
    end
  end
end
