# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Neighbour responses" do
  let!(:local_authority) { create(:local_authority, :default) }

  around do |example|
    travel_to("2025-05-23T12:00:00Z") { example.run }
  end

  context "when a planning application does not exist" do
    it "returns an error page" do
      expect {
        visit "/planning_applications/00-00000-000/neighbour_responses/start"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is not public" do
    let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }
    let!(:reference) { planning_application.reference }

    it "returns an error page" do
      expect {
        visit "/planning_applications/#{reference}/neighbour_responses/start"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is public" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :published,
        :in_assessment,
        :consulting,
        local_authority: local_authority,
        description: "Application for the erection of 47 dwellings",
        address_1: "60-62 Commercial Street",
        town: "London",
        postcode: "E1 6LT"
      )
    end

    let!(:reference) { planning_application.reference }
    let!(:consultation) { planning_application.consultation }

    it "allows a neighbour to submit a comment" do
      visit "/planning_applications/#{reference}"
      expect(page).to have_selector("h1", text: "60-62 Commercial Street, London, E1 6LT")
      expect(page).to have_content(reference)
      expect(page).to have_content("Application for the erection of 47 dwellings")

      within "#consultation-status" do
        expect(page).to have_content("Comment on this application by 6 June 2025")
        click_link "Submit a comment"
      end

      expect(page).to have_selector("h1", text: "Comment on a planning application")
      expect(page).to have_selector("h2", text: "Writing useful comments")
      expect(page).to have_selector("h2", text: "What we will consider")
      expect(page).to have_selector("h2", text: "What we cannot consider")
      expect(page).to have_selector("h2", text: "What happens next")
      expect(page).to have_content("We will make a decision about this application by 27 June 2025")

      click_link "Start now"
      expect(page).to have_selector("h1", text: "Your details")

      fill_in "Full name", with: "Alice Smith"
      fill_in "Email", with: "alice.smith@example.com"
      fill_in "Address", with: "1 Main Street, Barnacle, Coventry, CV7 1AA"

      click_button "Continue"
      expect(page).to have_selector("h1", text: "How do you feel about the proposed work?")

      choose "I support the application"

      click_button "Continue"
      expect(page).to have_selector("h1", text: "Share your comments about the proposed work")

      check "Other"
      fill_in "Use this space to share any other comments", with: "I think it looks great"

      click_button "Continue"
      expect(page).to have_selector("h1", text: "Check your comments before sending")

      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("alice.smith@example.com")
      expect(page).to have_content("1 Main Street, Barnacle, Coventry, CV7 1AA")
      expect(page).to have_content("You support the application")
      expect(page).to have_content("I think it looks great")

      attach_file "Upload documents", "spec/fixtures/files/images/proposed-floorplan.png"

      click_button "Send"
      expect(page).to have_selector("h1", text: "We've got your comments")
      expect(page).to have_content("The decision date for this application is 27 June 2025")

      click_link "Back to the planning application"
      expect(page).to have_selector("h1", text: "60-62 Commercial Street, London, E1 6LT")
      expect(page).to have_content(reference)
      expect(page).to have_content("Application for the erection of 47 dwellings")

      expect(consultation).to have_attributes(
        neighbour_responses: [
          an_object_having_attributes(
            name: "Alice Smith",
            email: "alice.smith@example.com",
            summary_tag: "supportive",
            response: "I think it looks great",
            tags: %w[other],
            neighbour: an_object_having_attributes(
              address: "1 Main Street, Barnacle, Coventry, CV7 1AA"
            ),
            documents: [
              an_object_having_attributes(name: "proposed-floorplan.png")
            ]
          )
        ]
      )
    end
  end
end
