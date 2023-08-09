# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:planning_application) do
    create(:planning_application, local_authority:)
  end

  let!(:consultation) { create(:consultation, end_date: "2023-07-08 16:17:35 +0100", planning_application:) }
  let!(:neighbour) { create(:neighbour, consultation:) }

  before do
    sign_in assessor
  end

  describe "viewing the consultations tasklist" do
    context "when there is an objection from a neighbour" do
      let!(:neighbour_response) { create(:neighbour_response, summary_tag: "objection", neighbour:) }

      it "shows the site visit item in the tasklist" do
        visit planning_application_path(planning_application)
        expect(page).to have_css("#site-visit")
      end
    end

    context "when a site visit response exists" do
      let!(:site_visit) { create(:site_visit, consultation:) }

      it "shows the site visit item in the tasklist" do
        visit planning_application_path(planning_application)
        expect(page).to have_css("#site-visit")
      end
    end

    context "when there is no objection from a neighbour or existing site visit response" do
      let!(:neighbour_response1) { create(:neighbour_response, summary_tag: "neutral", neighbour:) }
      let!(:neighbour_response2) { create(:neighbour_response, summary_tag: "supportive", neighbour:) }

      it "does not show the site visit item in the tasklist" do
        visit planning_application_path(planning_application)
        expect(page).not_to have_css("#site-visit")
      end
    end
  end

  describe "viewing site visits" do
    let!(:site_visit1) { create(:site_visit, consultation:, comment: "Site visit 1") }
    let!(:site_visit2) { create(:site_visit, decision: false, consultation:, comment: "Site visit 2") }
    let!(:neighbour_response) { create(:neighbour_response, summary_tag: "objection", neighbour:, received_at: Time.zone.now) }

    before do
      visit planning_application_path(planning_application)
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
      expect(page).to have_content("Date received: #{Time.zone.now.strftime('%d/%m/%Y')}")
      expect(page).to have_content("Respondent:")
      expect(page).to have_content("Email: neighbour@example.com")
      expect(page).to have_content("Address: #{neighbour.address}")
      expect(page).to have_content("Original version: I like it rude word")
      expect(page).to have_content("Redacted version: I like it *****")
    end

    context "when there are site visit responses" do
      it "I can see the previous responses and their details" do
        find("span", text: "See previous site visit responses").click
        within(".govuk-details__text") do
          expect(page).to have_content("Site visit needed: Yes")
          expect(page).to have_content("Response created by: #{site_visit1.created_by.name}")
          expect(page).to have_content("Response created at: #{site_visit1.created_at.to_fs}")
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
      visit planning_application_path(planning_application)
      within("#site-visit") do
        click_link "Site visit"
      end
    end

    it "there is a validation error when saving" do
      click_button "Save"

      within(".govuk-error-summary") do
        expect(page).to have_content("You must choose 'Yes' or 'No'")
        expect(page).to have_content("Comment can't be blank")
      end
      within("#site-visit-decision-error") do
        expect(page).to have_content("You must choose 'Yes' or 'No'")
      end
      within("#site-visit-comment-error") do
        expect(page).to have_content("can't be blank")
      end

      choose "Yes"
      attach_file("Upload photo(s)", "spec/fixtures/images/image.gif")
      click_button("Save")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
    end

    it "I can view the objected neighbour responses" do
      expect(page).to have_content("Objected neighbour responses")
      expect(page).to have_content("Objection")
      expect(page).to have_content("Date received: #{Time.zone.now.strftime('%d/%m/%Y')}")
      expect(page).to have_content("Respondent:")
      expect(page).to have_content("Email: neighbour@example.com")
      expect(page).to have_content("Address: #{neighbour.address}")
      expect(page).to have_content("Original version: I like it rude word")
      expect(page).to have_content("Redacted version: I like it *****")
    end

    context "when a site visit is taking place" do
      it "I choose yes and provide some information" do
        choose "Yes"
        fill_in "Day", with: "20"
        fill_in "Month", with: "7"
        fill_in "Year", with: "2023"

        attach_file("Upload photo(s)", "spec/fixtures/images/proposed-floorplan.png")

        fill_in "Comment", with: "Site visit is needed"
        click_button "Save"

        expect(page).to have_content("Site visit was successfully created.")

        within("#site-visit") do
          expect(page).to have_link(
            "Site visit",
            href: "/planning_applications/#{planning_application.id}/consultations/#{consultation.id}/site_visits"
          )
          expect(page).to have_content("Completed")

          click_link "Site visit"
        end

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
          "/planning_applications/#{planning_application.id}/consultations/#{consultation.id}/site_visits"
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
    end
  end
end
