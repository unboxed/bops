# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Planning applications" do
  let!(:local_authority) { create(:local_authority, :default) }

  around do |example|
    travel_to("2025-05-23T12:00:00Z") { example.run }
  end

  context "when a planning application does not exist" do
    it "returns an error page" do
      expect {
        visit "/planning_applications/00-00000-000"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is not public" do
    let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }
    let!(:reference) { planning_application.reference }

    it "returns an error page" do
      expect {
        visit "/planning_applications/#{reference}"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is public" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :published,
        consultation_status,
        local_authority: local_authority,
        description: "Application for the erection of 47 dwellings",
        address_1: "60-62 Commercial Street",
        town: "London",
        postcode: "E1 6LT"
      )
    end

    let!(:reference) { planning_application.reference }
    let!(:consultation) { planning_application.consultation }

    context "and the consultation has not started" do
      let(:consultation_status) { :not_consulting }

      it "displays the public summary page" do
        visit "/planning_applications/#{reference}"

        expect(page).to have_selector("h1", text: "60-62 Commercial Street, London, E1 6LT")
        expect(page).to have_content(reference)
        expect(page).to have_content("Application for the erection of 47 dwellings")
        expect(page).not_to have_content("Comment on this application by 6 June 2025")
        expect(page).to have_link("Submit a comment", href: "/planning_applications/#{reference}/neighbour_responses/start")
      end
    end

    context "and the consultation has started" do
      let(:consultation_status) { :consulting }

      it "displays the public summary page" do
        visit "/planning_applications/#{reference}"

        expect(page).to have_selector("h1", text: "60-62 Commercial Street, London, E1 6LT")
        expect(page).to have_content(reference)
        expect(page).to have_content("Application for the erection of 47 dwellings")
        expect(page).to have_content("Comment on this application by 6 June 2025")
        expect(page).to have_link("Submit a comment", href: "/planning_applications/#{reference}/neighbour_responses/start")
      end
    end
  end
end
