# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Service navigation", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "highlights Dashboard on the dashboard page" do
    visit "/admin/dashboard"

    expect(page).to have_selector("a[aria-current]", text: "Dashboard")
  end

  it "highlights Applications on the consultees page" do
    visit "/admin/consultees"

    expect(page).to have_selector("a[aria-current]", text: "Applications")
  end

  it "highlights Policies on the policies page" do
    visit "/admin/policy"

    expect(page).to have_selector("a[aria-current]", text: "Policies")
  end

  context "when viewing policy nested pages" do
    it "highlights Policies on the informatives page" do
      visit "/admin/informatives"

      expect(page).to have_selector("a[aria-current]", text: "Policies")
    end

    it "highlights Policies on the policy areas page" do
      visit "/admin/policy/areas"

      expect(page).to have_selector("a[aria-current]", text: "Policies")
    end

    it "highlights Policies on the policy guidances page" do
      visit "/admin/policy/guidance"

      expect(page).to have_selector("a[aria-current]", text: "Policies")
    end

    it "highlights Policies on the policy references page" do
      visit "/admin/policy/references"

      expect(page).to have_selector("a[aria-current]", text: "Policies")
    end
  end

  it "highlights Users & Access on the users page" do
    visit "/admin/users"

    expect(page).to have_selector("a[aria-current]", text: "Users & Access")
  end

  context "when viewing users nested pages" do
    it "highlights Users & Access on the tokens page" do
      visit "/admin/tokens"

      expect(page).to have_selector("a[aria-current]", text: "Users & Access")
    end
  end

  it "highlights Submissions on the submissions page" do
    visit "/admin/submissions"

    expect(page).to have_selector("a[aria-current]", text: "Submissions")
  end

  it "highlights Settings on the profile page" do
    visit "/admin/profile"

    expect(page).to have_selector("a[aria-current]", text: "Settings")
  end

  context "when viewing settings nested pages" do
    it "highlights Settings on the application types page" do
      visit "/admin/application_types"

      expect(page).to have_selector("a[aria-current]", text: "Settings")
    end
  end
end
