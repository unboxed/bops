# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Drawing a sitemap on a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority, name: "Assessor 1") }

  before do
    sign_in assessor
    visit(planning_application_assessment_tasks_path(planning_application))
  end

  context "when application is not_started" do
    let!(:planning_application) do
      create(:planning_application, :not_started, boundary_geojson:, local_authority: default_local_authority)
    end

    context "without boundary geojson" do
      let(:boundary_geojson) { nil }

      before do
        boundary_geojson
      end

      it "displays the planning application address and reference" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.reference)
      end

      it "is possible to create a sitemap" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        # When no boundary set, map should be displayed zoomed in at latitiude/longitude if fields present
        map_selector = find("my-map")
        expect(map_selector["latitude"]).to eq(planning_application.latitude)
        expect(map_selector["longitude"]).to eq(planning_application.longitude)
        expect(map_selector["showMarker"]).to eq("true")

        # JS to emulate a polygon drawn on the map
        execute_script 'document.getElementById("planning_application_boundary_geojson").setAttribute("value", \'{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}\')'
        click_button "Save"

        expect(page).to have_content("Site boundary has been updated")
        expect(page).not_to have_content("No digital sitemap provided")
      end
    end

    context "with boundary geojson" do
      let(:boundary_geojson) { '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.054597,51.537331],[-0.054588,51.537287],[-0.054453,51.537313],[-0.054597,51.537331]]]}}' }

      before do
        boundary_geojson
      end

      it "is not possible to edit the sitemap" do
        click_button "Site map"
        expect(page).to have_content("Site map drawn by applicant")
        expect(page).not_to have_content("No digital sitemap provided")
        map = find("my-map")
        expect(map["showMarker"]).to eq("false")

        visit planning_application_validation_tasks_path(planning_application)
        expect(page).not_to have_link("Draw red line boundary")
      end
    end
  end

  context "when application is already validated but has no boundary" do
    let!(:planning_application) do
      create(:planning_application, local_authority: default_local_authority)
    end

    it "is not possible to create a sitemap" do
      click_button "Site map"
      expect(page).to have_content("No digital site map provided")
      expect(page).not_to have_link("Draw digital sitemap")
    end
  end

  context "when linking to sitemap documents" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end
    let!(:document_notsitemap) { create(:document, tags: %w[Plan], planning_application:) }

    context "with 0 documents tagged with sitemap" do
      it "links to all documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content("No document has been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end

    context "with 1 document tagged with sitemap" do
      let!(:document1) { create(:document, tags: %w[Site], planning_application:) }

      it "links to that documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content("This digital red line boundary was submitted by the applicant on PlanX")
        expect(page).to have_link("View sitemap document")
      end
    end

    context "with 2 document tagged with sitemap" do
      let!(:document1) { create(:document, tags: %w[Site], planning_application:) }
      let!(:document2) { create(:document, tags: %w[Site], planning_application:) }

      it "links to all documents" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Draw red line boundary"

        expect(page).to have_content("This digital red line boundary was submitted by the applicant on PlanX")
        expect(page).to have_content("Multiple documents have been tagged as a sitemap for this application")
        expect(page).to have_link("View all documents")
      end
    end
  end

  context "when requesting map changes to a planning application" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, :with_boundary_geojson, local_authority: default_local_authority)
    end

    let!(:api_user) { create(:api_user, name: "Api Wizard") }

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

      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.reference)
      map = find("my-map")
      expect(map["showMarker"]).to eq("true")

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
      let(:boundary_geojson) do
        {
          type: "Feature",
          properties: {},
          geometry: {
            type: "Polygon",
            coordinates: [
              [
                [-0.054597, 51.537331],
                [-0.054588, 51.537287],
                [-0.054453, 51.537313],
                [-0.054597, 51.537331]
              ]
            ]
          }
        }.to_json
      end

      let(:new_geojson_feature) do
        {
          type: "Feature",
          properties: {},
          geometry: {
            type: "Polygon",
            coordinates: [
              [
                [-0.054597, 51.537332],
                [-0.054588, 51.537288],
                [-0.054453, 51.537312],
                [-0.054597, 51.537332]
              ]
            ]
          }
        }
      end

      let(:new_geojson) do
        { type: "FeatureCollection", features: [new_geojson_feature] }.to_json
      end

      before do
        find(".govuk-visually-hidden", visible: false).set(new_geojson)
        fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: ""
        click_button "Send request"
      end

      it "throws an error" do
        expect(page).to have_content("There is a problem")
        expect(page).not_to have_content("Red line drawing must be complete")
        expect(page).to have_content("Provide a reason for changes")

        expect(find("my-map")[:geojsondata]).to eq(boundary_geojson)

        expect(
          find("my-map")[:drawgeojsondata]
        ).to eq(
          new_geojson_feature.to_json
        )

        fill_in(
          "Explain to the applicant why changes are proposed to the red line boundary",
          with: "Reason for change"
        )

        click_button("Send request")
        click_link("Check red line boundary")

        expect(find_all("my-map")[0][:geojsondata]).to eq(boundary_geojson)
        expect(find_all("my-map")[1][:geojsondata]).to eq(new_geojson)
      end
    end
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, :with_boundary_geojson, local_authority: default_local_authority)
    end

    it "as an officer I can request approval for a change to the red line boundary" do
      delivered_emails = ActionMailer::Base.deliveries.count

      click_button "Site map"
      click_link "Request approval for a change to red line boundary"
      map = find("my-map")
      expect(map["showMarker"]).to eq("true")

      # Draw proposed red line boundary
      find(".govuk-visually-hidden", visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'

      fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Amendment request"
      click_button "Send request"
      expect(page).to have_content("Validation request for red line boundary successfully created.")

      expect(page).to have_current_path(
        planning_application_assessment_tasks_path(planning_application)
      )

      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)

      click_link("Application")
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Sent: Post-validation request (red line boundary#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Reason: Amendment request")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end

      click_link "Application"
      click_link "Review non-validation requests"
      within(".validation-requests-table") do
        expect(page).to have_content("Red line boundary changes")
      end

      click_link("Application")
      click_link("Check and assess")
      click_button "Site map"
      expect(page).not_to have_content("Request approval for a change to red line boundary")

      click_link "View requested red line boundary change"
      expect(page).to have_content("Current red line boundary")
      expect(page).to have_content("Amendment request")
      expect(page).to have_content("Proposed red line boundary")

      # Cancel post validation request
      click_link "Cancel request"

      fill_in "Explain to the applicant why this request is being cancelled", with: "no longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_content("Validation request was successfully cancelled.")
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 2)

      within(".cancelled-requests") do
        expect(page).to have_content("Red line boundary changes")
      end

      click_link "Back"
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Cancelled: Post-validation request (red line boundary#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Reason: no longer needed")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when applicant accepts the response" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :closed, approved: true, planning_application:)
      end

      it "I can view the accepted response" do
        visit(planning_application_assessment_tasks_path(planning_application))
        click_button "Site map"
        click_link "View applicants response to requested red line boundary change"

        expect(page).to have_content("Applicant approved proposed digital red line boundary")
        expect(page).to have_content("Change to red line boundary has been approved by the applicant")
        map = find("my-map")
        expect(map["showMarker"]).to eq("false")
      end
    end

    context "when applicant rejects the response" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :closed, rejection_reason: "disagree", approved: false, planning_application:)
      end

      it "I can view the rejected response" do
        visit(planning_application_assessment_tasks_path(planning_application))
        click_button "Site map"
        click_link "View applicants response to requested red line boundary change"

        expect(page).to have_content("Applicant rejected this proposed red line boundary")
        expect(page).to have_content("Reason: disagree")
        map = find("my-map")
        expect(map["showMarker"]).to eq("false")
      end
    end

    context "when request has been auto closed" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :open, planning_application:)
      end

      before do
        red_line_boundary_change_validation_request.auto_close_request!
      end

      it "I can view the accepted response" do
        visit(planning_application_assessment_tasks_path(planning_application))
        click_button "Site map"
        click_link "View applicants response to requested red line boundary change"

        expect(page).to have_content("Change to red line boundary was auto closed and approved after being open for more than 5 business days")
        map = find("my-map")
        expect(map["showMarker"]).to eq("false")

        visit planning_application_audits_path(planning_application)

        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Auto-closed: validation request (red line boundary#1)")
          expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end
    end
  end
end
