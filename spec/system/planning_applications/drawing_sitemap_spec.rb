# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Drawing a sitemap on a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 1" }

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when application is not_started" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: @default_local_authority
    end

    it "is possible to create and edit a sitemap" do
      click_button "Site map"
      expect(page).to have_content("No digital sitemap provided")
      click_link "Draw digital sitemap"

      # JS to emulate a polygon drawn on the map
      execute_script 'document.getElementById("planning_application_boundary_geojson").setAttribute("value", \'{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}\')'
      click_button "Save"

      expect(page).to have_content("Site boundary has been updated")
      expect(page).not_to have_content("No digital sitemap provided")
      expect(page).to have_content("Sitemap drawn by Assessor 1")

      click_button "Site map"
      click_link "Redraw digital sitemap"

      execute_script 'document.getElementById("planning_application_boundary_geojson").setAttribute("value", \'{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313]]]}}\')'
      click_button "Save"

      expect(page).to have_content("Site boundary has been updated")

      click_button "Audit log"
      click_link "View all"
      expect(page).to have_content("Red line drawing created")
      expect(page).to have_content("Red line drawing updated")
    end
  end

  context "when application is already validated but has no boundary" do
    let!(:planning_application) do
      create :planning_application, local_authority: @default_local_authority
    end

    it "is not possible to create a sitemap" do
      click_button "Site map"
      expect(page).to have_content("No digital sitemap provided")
      expect(page).not_to have_link("Draw digital sitemap")
    end
  end

  context "when application is already validated and has a boundary" do
    let!(:planning_application) do
      create :planning_application, :with_boundary_geojson, local_authority: @default_local_authority
    end

    it "is not possible to edit the sitemap" do
      click_button "Site map"
      expect(page).to have_content("Sitemap drawn by Applicant")
      expect(page).not_to have_content("No digital sitemap provided")
      expect(page).not_to have_link("Redraw digital sitemap")
    end
  end

  context "linking to sitemap documents" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: @default_local_authority
    end
    let!(:document_notsitemap) { create :document, tags: %w[Plan], planning_application: planning_application }

    context "with 0 documents tagged with sitemap" do
      it "links to all documents" do
        click_button "Site map"
        click_link "Draw digital sitemap"
        expect(page).to have_content("No document has been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end

    context "with 1 document tagged with sitemap" do
      let!(:document1) { create :document, tags: %w[Site], planning_application: planning_application }

      it "links to that documents" do
        click_button "Site map"
        click_link "Draw digital sitemap"
        expect(page).to have_link("View sitemap document")
      end
    end

    context "with 2 document tagged with sitemap" do
      let!(:document1) { create :document, tags: %w[Site], planning_application: planning_application }
      let!(:document2) { create :document, tags: %w[Site], planning_application: planning_application }

      it "links to all documents" do
        click_button "Site map"
        click_link "Draw digital sitemap"
        expect(page).to have_content("Multiple documents have been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end
  end
end
