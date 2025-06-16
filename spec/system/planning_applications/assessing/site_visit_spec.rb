# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application, :from_planx_prior_approval,
      application_type:, local_authority:)
  end

  let(:consultation) { planning_application.consultation }
  let(:neighbour) { create(:neighbour, consultation:) }
  let(:neighbour2) { create(:neighbour, consultation:, address: "123, Another, Address") }

  before do
    travel_to("2023-07-21")

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses)
      .with("60-")
      .and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, LONDON, E16LT"}}]}))

    sign_in(assessor)
  end

  describe "viewing the assessment tasklist" do
    context "when site visits are enabled" do
      it "shows the site visit item in the tasklist" do
        visit "/planning_applications/#{planning_application.reference}"
        click_link "Check and assess"

        within("#additional-services-tasks") do
          expect(page).to have_css("#site-visit")
        end
      end
    end

    context "when site visits are disabled" do
      before do
        application_type.update!(features: {"site_visits" => false})
      end

      it "does not show the site visit item in the tasklist" do
        visit "/planning_applications/#{planning_application.reference}"
        click_link "Check and assess"

        expect(page).not_to have_css("#site-visit")
      end
    end
  end

  describe "viewing site visits" do
    let!(:site_visit1) { create(:site_visit, planning_application:, comment: "Site visit 1", neighbour:) }
    let!(:site_visit2) { create(:site_visit, decision: false, planning_application:, comment: "Site visit 2") }
    let!(:neighbour_response) { create(:neighbour_response, summary_tag: "objection", neighbour:, received_at: Time.zone.now) }

    before do
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
      click_link "Site visit"
    end

    it "I can see the application information" do
      within("#planning-application-details") do
        expect(page).to have_content("View site visits")
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.description)
      end
    end

    it "I can view the objected neighbour responses" do
      expect(page).to have_content("Objected neighbour responses")
      expect(page).to have_content("Objection")
      expect(page).to have_content("Received on #{Time.zone.now.strftime("%d/%m/%Y")}")
      expect(page).to have_content("neighbour@example.com")
      expect(page).to have_content(neighbour.address.to_s)
      expect(page).to have_content("I like it *****")
    end

    context "when there are site visit responses" do
      it "I can see the previous responses and their details" do
        find("span", text: "See previous site visit responses").click
        within(".govuk-details__text") do
          expect(page).to have_content("Site visit needed: Yes")
          expect(page).to have_content("Response created by: #{site_visit1.created_by.name}")
          expect(page).to have_content("Response created at: #{site_visit1.created_at.to_fs}")
          expect(page).to have_content("Neighbour: #{site_visit1.neighbour.address}")
          expect(page).to have_content("Comment: Site visit 1")

          expect(page).to have_content("Site visit needed: No")
          expect(page).to have_content("Response created by: #{site_visit2.created_by.name}")
          expect(page).to have_content("Response created at: #{site_visit2.created_at.to_fs}")
          expect(page).to have_content("Comment: Site visit 2")
        end

        expect(page).to have_link("Add site visit response")
      end
    end
  end

  describe "adding a new site visit response" do
    let!(:neighbour_response) { create(:neighbour_response, summary_tag: "objection", neighbour:, received_at: Time.zone.now) }

    before do
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
      within("#site-visit") do
        click_link "Site visit"
      end
    end

    it "there is a validation error when saving" do
      click_button "Save"

      within(".govuk-error-summary") do
        expect(page).to have_content("Choose 'Yes' or 'No'")
      end
      within("#site-visit-decision-error") do
        expect(page).to have_content("Choose 'Yes' or 'No'")
      end

      choose "Yes"
      click_button("Save")

      within(".govuk-error-summary") do
        expect(page).to have_content("Enter a comment about the site visit")
      end
      within("#site-visit-comment-error") do
        expect(page).to have_content("Enter a comment about the site visit")
      end

      attach_file("Upload photo(s)", "spec/fixtures/images/image.gif")
      click_button("Save")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")

      within("#site-visit-visited-at-error") do
        expect(page).to have_content("Provide the date when the site visit took place")
      end
    end

    it "I can view the objected neighbour responses" do
      expect(page).to have_content("Objected neighbour responses")
      expect(page).to have_content("Objection")
      expect(page).to have_content("Received on #{Time.zone.now.strftime("%d/%m/%Y")}")
      expect(page).to have_content("neighbour@example.com")
      expect(page).to have_content(neighbour.address.to_s)
      expect(page).to have_content("I like it *****")
    end

    it "I can't add a site visit after the current date" do
      planning_application = create(:planning_application, :planning_permission, local_authority:)

      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
      within("#site-visit") do
        click_link "Site visit"
      end

      choose "Yes"
      fill_in "Day", with: "1"
      fill_in "Month", with: "1"
      fill_in "Year", with: "2024"
      fill_in "Comment", with: "Comment"
      click_button("Save")

      expect(page).to have_content "The date the site visit took place must be on or before today"
    end

    context "when a site visit is taking place", js: true do
      before do
        allow_any_instance_of(PlanningApplication).to receive(:address).and_return("140, WOODWARDE ROAD, LONDON, SE22 8UR")
      end

      it "I choose yes and provide some information" do
        visit "/planning_applications/#{planning_application.reference}/assessment/site_visits/new"

        choose "Yes"
        fill_in "Day", with: "20"
        fill_in "Month", with: "7"
        fill_in "Year", with: "2023"

        # Default address is set to the planning application address
        expect(page).to have_field("Search for address", with: "140, WOODWARDE ROAD, LONDON, SE22 8UR")

        fill_in "Search for address", with: "60-"

        page.find(:xpath, "//li[text()='60-62, Commercial Street, LONDON, E16LT']").click

        attach_file("Upload photo(s)", "spec/fixtures/images/proposed-floorplan.png")

        fill_in "Comment", with: "Site visit is needed"
        click_button "Save"

        expect(page).to have_content("Site visit response was successfully added.")

        expect(page).to have_link(
          "Site visit",
          href: "/planning_applications/#{planning_application.reference}/assessment/site_visits"
        )
        expect(page).to have_content("Completed")

        click_link "Site visit"

        find("span", text: "See previous site visit responses").click
        within(".govuk-details__text") do
          expect(page).to have_content("Site visit needed: Yes")
          expect(page).to have_content("Response created by: #{assessor.name}")
          expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
          expect(page).to have_content("Visited at: 20 July 2023")
          expect(page).to have_content("Comment: Site visit is needed")
          expect(page).to have_content("1 document added")

          click_link "View"
        end

        expect(page).to have_content("View site visit")
        expect(page).to have_content("Site visit response")

        expect(page).to have_content("Site visit needed: Yes")
        expect(page).to have_content("Response created by: #{assessor.name}")
        expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
        expect(page).to have_content("Visited at: 20 July 2023")
        expect(page).to have_content("Comment: Site visit is needed")

        within(".govuk-table") do
          document = SiteVisit.last.documents.first
          expect(page).to have_content(document.name.to_s)
          expect(page).to have_link("View in new window")
          expect(page).to have_content("Site Visit")
          expect(page).to have_content(document.created_at.to_fs)
        end

        click_link "Back"
        expect(current_url).to include(
          "/planning_applications/#{planning_application.reference}/assessment/site_visits"
        )
      end
    end

    context "when a site visit is not taking place" do
      it "I choose no and give a reason why" do
        choose "No"

        fill_in "Comment", with: "Site visit not needed"
        click_button "Save"

        within("#site-visit") do
          expect(page).to have_content("Completed")

          click_link "Site visit"
        end

        find("span", text: "See previous site visit responses").click
        within(".govuk-details__text") do
          expect(page).to have_content("Site visit needed: No")
          expect(page).to have_content("Response created by: #{assessor.name}")
          expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
          expect(page).not_to have_content("Visited at")
          expect(page).to have_content("Comment: Site visit not needed")

          click_link "View"
        end

        expect(page).to have_content("Site visit needed: No")
        expect(page).to have_content("Response created by: #{assessor.name}")
        expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
        expect(page).not_to have_content("Visited at")
        expect(page).to have_content("Comment: Site visit not needed")

        expect(page).not_to have_css(".govuk-table")
      end

      it "I do not have give a reason why if I choose no" do
        choose "No"
        click_button "Save"

        within("#site-visit") do
          expect(page).to have_content("Completed")
        end
      end
    end
  end

  describe "when no consultation exists" do
    context "when adding a site visit response" do
      let!(:application_type) { create(:application_type, :without_consultation) }
      let!(:planning_application) do
        create(:planning_application, application_type:, local_authority:)
      end

      it "I can manually pick the address for the site visit", js: true do
        visit "/planning_applications/#{planning_application.reference}"
        click_link "Check and assess"
        click_link "Site visit"

        choose "Yes"
        fill_in "Day", with: "20"
        fill_in "Month", with: "7"
        fill_in "Year", with: "2023"

        fill_in "Search for address", with: "60-"

        page.find(:xpath, "//li[text()='60-62, Commercial Street, LONDON, E16LT']").click

        attach_file("Upload photo(s)", "spec/fixtures/images/proposed-floorplan.png")

        fill_in "Comment", with: "Site visit is required"
        click_button "Save"

        expect(page).to have_content("Site visit response was successfully added.")
        within("#site-visit") do
          expect(page).to have_content("Completed")
          click_link "Site visit"
        end

        find("span", text: "See previous site visit responses").click
        within(".govuk-details__text") do
          expect(page).to have_content("Site visit needed: Yes")
          expect(page).to have_content("Response created by: #{assessor.name}")
          expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
          expect(page).to have_content("Visited at: 20 July 2023")
          expect(page).to have_content("Comment: Site visit is required")
          expect(page).to have_content("Address: 60-62, Commercial Street, LONDON, E16LT")
          expect(page).to have_content("1 document added")

          click_link "View"
        end

        expect(page).to have_content("View site visit")
        expect(page).to have_content("Site visit response")

        expect(page).to have_content("Site visit needed: Yes")
        expect(page).to have_content("Response created by: #{assessor.name}")
        expect(page).to have_content("Response created at: #{SiteVisit.last.created_at.to_fs}")
        expect(page).to have_content("Visited at: 20 July 2023")
        expect(page).to have_content("Comment: Site visit is required")
        expect(page).to have_content("Address: 60-62, Commercial Street, LONDON, E16LT")

        within(".govuk-table") do
          document = SiteVisit.last.documents.first
          expect(page).to have_content(document.name.to_s)
          expect(page).to have_link("View in new window")
          expect(page).to have_content("Site Visit")
          expect(page).to have_content(document.created_at.to_fs)
        end
      end
    end
  end
end
