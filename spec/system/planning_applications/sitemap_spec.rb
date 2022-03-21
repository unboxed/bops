# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Drawing a sitemap on a planning application", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority, name: "Assessor 1" }

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when application is not_started" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: default_local_authority
    end

    it "is possible to create a sitemap" do
      click_button "Site map"
      expect(page).to have_content("No digital sitemap provided")

      visit planning_application_validation_tasks_path(planning_application)
      click_link "Draw red line boundary"

      # When no boundary set, map should be displayed zoomed in at latitiude/longitude if fields present
      map_selector = find("my-map")
      expect(map_selector["latitude"]).to eq(planning_application.latitude)
      expect(map_selector["longitude"]).to eq(planning_application.longitude)

      # JS to emulate a polygon drawn on the map
      execute_script 'document.getElementById("planning_application_boundary_geojson").setAttribute("value", \'{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}\')'
      click_button "Save"

      expect(page).to have_content("Site boundary has been updated")
      expect(page).not_to have_content("No digital sitemap provided")

      visit planning_application_path(planning_application)
      click_button "Site map"

      expect(page).to have_content("Sitemap drawn by Assessor 1")

      click_button "Audit log"
      click_link "View all audits"
      expect(page).to have_content("Red line drawing created")
    end
  end

  context "when application is already validated but has no boundary" do
    let!(:planning_application) do
      create :planning_application, local_authority: default_local_authority
    end

    it "is not possible to create a sitemap" do
      click_button "Site map"
      expect(page).to have_content("No digital sitemap provided")
      expect(page).not_to have_link("Draw digital sitemap")
    end
  end

  context "when application is not started and has a boundary" do
    let!(:planning_application) do
      create :planning_application, :with_boundary_geojson, :not_started, local_authority: default_local_authority
    end

    it "is not possible to edit the sitemap" do
      click_button "Site map"
      expect(page).to have_content("Sitemap drawn by Applicant")
      expect(page).not_to have_content("No digital sitemap provided")

      visit planning_application_validation_tasks_path(planning_application)
      expect(page).not_to have_link("Draw red line boundary")
    end
  end

  context "linking to sitemap documents" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: default_local_authority
    end
    let!(:document_notsitemap) { create :document, tags: %w[Plan], planning_application: planning_application }

    context "with 0 documents tagged with sitemap" do
      it "links to all documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content("No document has been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end

    context "with 1 document tagged with sitemap" do
      let!(:document1) { create :document, tags: %w[Site], planning_application: planning_application }

      it "links to that documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_link("View sitemap document")
      end
    end

    context "with 2 document tagged with sitemap" do
      let!(:document1) { create :document, tags: %w[Site], planning_application: planning_application }
      let!(:document2) { create :document, tags: %w[Site], planning_application: planning_application }

      it "links to all documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content("Multiple documents have been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end
  end
end
