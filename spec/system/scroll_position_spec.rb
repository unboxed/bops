# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scroll position" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
  end

  context "when navigating back to a page" do
    before do
      visit planning_application_validation_tasks_path(planning_application)

      # Resize window so there is capacity to scroll the page
      page.current_window.resize_to(700, 1400)
    end

    it "remembers my scroll position" do
      # Scroll down the page
      page.execute_script "window.scrollBy(0, 800)"
      expect(page.evaluate_script("window.scrollY")).to eq(800)

      click_link("Review validation requests")
      click_link("Back")

      # Returns user to the exact scroll position that they left the page on
      expect(page.evaluate_script("window.scrollY")).to eq(800)

      # Now scroll back up
      page.execute_script "window.scrollBy(0, -650)"
      expect(page.evaluate_script("window.scrollY")).to eq(150)

      click_link "Application"
      click_link "Check and validate"

      expect(page.evaluate_script("window.scrollY")).to eq(150)
    end
  end

  context "when navigating back to the home page" do
    before do
      visit(root_path)

      # Resize window so there is capacity to scroll the page
      page.current_window.resize_to(200, 400)
      page.execute_script "window.scrollBy(0, 350)"
    end

    it "returns me to the top of the page" do
      click_link("Add new application")
      click_link("PlanX Back-office Planning System")

      expect(page.evaluate_script("window.scrollY")).to eq(0)
    end
  end
end
