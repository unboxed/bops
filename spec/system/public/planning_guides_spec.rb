# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning guides", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }

  context "when not logged in" do
    before do
      visit "planning_guides/index"
    end

    it "the planning guide index page is publicy accessible" do
      expect(page).to have_content("Find out how to create a valid plan")
      within(".govuk-header__content") do
        expect(page).to have_link("Back-office Planning System: #{default_local_authority.name}",
                                  href: "/planning_guides/index")
      end

      within(".govuk-grid-column-two-thirds") do
        expect(page).to have_content("All drawings")
        expect(page).to have_link("All drawings and plans", href: "/planning_guides/drawings")

        expect(page).to have_content("Floor plans")
        expect(page).to have_link("Existing floor plans", href: "/planning_guides/floor_plans/existing")
        expect(page).to have_link("Proposed floor plans", href: "/planning_guides/floor_plans/proposed")

        expect(page).to have_content("Site plans")
        expect(page).to have_link("Existing site plans", href: "/planning_guides/site_plans/existing")
        expect(page).to have_link("Proposed site plans", href: "/planning_guides/site_plans/proposed")

        expect(page).to have_content("Elevations")
        expect(page).to have_link("Existing elevations", href: "/planning_guides/elevations/existing")
        expect(page).to have_link("Proposed elevations", href: "/planning_guides/elevations/proposed")

        expect(page).to have_content("Sections")
        expect(page).to have_link("Existing sections", href: "/planning_guides/sections/existing")
        expect(page).to have_link("Proposed sections", href: "/planning_guides/sections/proposed")

        expect(page).to have_content("Roof plans")
        expect(page).to have_link("Existing roof plans", href: "/planning_guides/roof_plans/existing")
        expect(page).to have_link("Proposed roof plans", href: "/planning_guides/roof_plans/proposed")

        expect(page).to have_content("Unit plans")
        expect(page).to have_link("Existing unit plans", href: "/planning_guides/unit_plans/existing")
        expect(page).to have_link("Proposed unit plans", href: "/planning_guides/unit_plans/proposed")

        expect(page).to have_content("Use plans")
        expect(page).to have_link("Existing use plans", href: "/planning_guides/use_plans/existing")
        expect(page).to have_link("Proposed use plans", href: "/planning_guides/use_plans/proposed")
      end
    end

    it "drawings page" do
      click_link("All drawings and plans")

      expect(page).to have_content("How to create all drawings and plans")
      expect(page).to have_image_displayed("drawing_plans")
      expect(page).to have_link("Back", href: "/planning_guides/index")
    end

    it "floor plans pages" do
      click_link("Existing floor plans")

      expect(page).to have_content("How to create existing floor plans")
      expect(page).to have_image_displayed("floor_plans/existing")
      click_link("Back")

      click_link("Proposed floor plans")

      expect(page).to have_content("How to create proposed floor plans")
      expect(page).to have_image_displayed("floor_plans/proposed")
      expect(page).to have_link("Back", href: "/planning_guides/index")
    end

    it "site plans pages" do
      click_link("Existing site plans")

      expect(page).to have_content("How to create existing site plans")
      expect(page).to have_image_displayed("site_plans/existing")
      click_link("Back")

      click_link("Proposed site plans")

      expect(page).to have_content("How to create proposed site plans")
      expect(page).to have_image_displayed("site_plans/proposed")
      expect(page).to have_link("Back", href: "/planning_guides/index")
    end

    it "elevations pages" do
      click_link("Existing elevations")

      expect(page).to have_content("How to create existing elevations")
      expect(page).to have_image_displayed("elevations/existing")
      click_link("Back")

      click_link("Proposed elevations")

      expect(page).to have_content("How to create proposed elevations")
      expect(page).to have_image_displayed("elevations/proposed")
      expect(page).to have_link("Back", href: "/planning_guides/index")
    end

    it "sections pages" do
      click_link("Existing sections")

      expect(page).to have_content("How to create existing sections")
      expect(page).to have_image_displayed("sections/existing")
      click_link("Back")

      click_link("Proposed sections")

      expect(page).to have_content("How to create proposed sections")
      expect(page).to have_image_displayed("sections/proposed")
      expect(page).to have_link("Back", href: "/planning_guides/index")
    end
  end

  context "when logged in" do
    let(:user) { create(:user, local_authority: default_local_authority) }

    before do
      sign_in(user)

      visit "planning_guides/index"
    end

    it "is accessible" do
      expect(page).to have_content("Find out how to create a valid plan")
      within(".govuk-header__content") do
        expect(page).to have_link("Back-office Planning System: #{default_local_authority.name}",
                                  href: "/planning_guides/index")
      end
    end
  end
end
