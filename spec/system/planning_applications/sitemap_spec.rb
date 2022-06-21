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
      create :planning_application, :not_started, boundary_geojson: boundary_geojson, local_authority: default_local_authority
    end

    context "without boundary geojson" do
      let(:boundary_geojson) { nil }

      before do
        boundary_geojson
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

    context "with boundary geojson" do
      let(:boundary_geojson) { '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}' }

      before do
        boundary_geojson
      end

      it "is not possible to edit the sitemap" do
        click_button "Site map"
        expect(page).to have_content("Sitemap drawn by Applicant")
        expect(page).not_to have_content("No digital sitemap provided")

        visit planning_application_validation_tasks_path(planning_application)
        expect(page).not_to have_link("Draw red line boundary")
      end
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

  context "requesting map changes to a planning application" do
    let!(:planning_application) do
      create :planning_application, :invalidated, :with_boundary_geojson, local_authority: default_local_authority
    end

    let!(:api_user) { create :api_user, name: "Api Wizard" }

    before do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Check red line boundary"

      within("fieldset", text: "Is this red line boundary valid?") do
        choose "Invalid"
      end

      click_button "Save"
    end

    it "creates a request to update map boundary" do
      delivered_emails = ActionMailer::Base.deliveries.count

      find(".govuk-visually-hidden",
           visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'
      fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
      click_button "Send request"

      expect(page).to have_content("Validation request for red line boundary successfully created.")

      click_link("Check red line boundary")
      expect(page).to have_content("Coordinates look wrong")

      within(".govuk-heading-l") do
        expect(page).to have_text("Proposed red line boundary change")
      end

      # Two maps should be displayed with the original geojson and what the proposed change was
      map_selectors = all("my-map")
      red_line_boundary_change_validation_request = planning_application.red_line_boundary_change_validation_requests.last
      expect(map_selectors.first["geojsondata"]).to eq(red_line_boundary_change_validation_request.original_geojson)
      expect(map_selectors.last["geojsondata"]).to eq(red_line_boundary_change_validation_request.new_geojson)

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      expect(page).to have_text("Sent: validation request (red line boundary#1)")
      expect(page).to have_text("Coordinates look wrong")
      expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
    end

    context "when red line boundary is not drawn and reason not provided" do
      before do
        find(".govuk-visually-hidden", visible: false).set ""
        fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: " "
        click_button "Send request"
      end

      it "throws an error" do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Red line drawing must be complete")
        expect(page).to have_content("Provide a reason for changes")
      end
    end

    context "when red line boundary is not drawn" do
      before do
        find(".govuk-visually-hidden", visible: false).set ""
        fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Wrong line"
        click_button "Send request"
      end

      it "throws an error" do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Red line drawing must be complete")
        expect(page).not_to have_content("Provide a reason for changes")
      end
    end

    context "when reason is not provided" do
      before do
        find(".govuk-visually-hidden", visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'
        fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: ""
        click_button "Send request"
      end

      it "throws an error" do
        expect(page).to have_content("There is a problem")
        expect(page).not_to have_content("Red line drawing must be complete")
        expect(page).to have_content("Provide a reason for changes")
      end
    end
  end
end
