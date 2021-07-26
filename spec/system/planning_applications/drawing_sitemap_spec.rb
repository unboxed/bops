# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Drawing a sitemap on a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 1" }

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when no digital sitemap exists" do
    let!(:planning_application) do
      create :planning_application, local_authority: @default_local_authority
    end

    it "is possible to create a sitemap when application is not_started" do
      click_button "Site map"
      expect(page).to have_content("No digital sitemap provided")
      click_link "Draw digital sitemap"

      # JS to emulate a polygon drawn on the map
      execute_script 'document.getElementById("planning_application_boundary_geojson").setAttribute("value", \'{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}\')'
      click_button "Save"

      expect(page).to have_content("Site boundary has been updated")
      expect(page).not_to have_content("No digital sitemap provided")
    end
  end
end
