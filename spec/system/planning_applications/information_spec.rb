# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application information", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :listed, local_authority:) }
  let(:planning_application) do
    create(
      :planning_application,
      :with_boundary_geojson,
      :published,
      local_authority:,
      application_type:
    )
  end
  let(:reference) { planning_application.reference }
  let!(:document) { create(:document, planning_application:) }
  let!(:document2) { create(:document, :archived, :with_other_file, planning_application:) }
  let!(:site_history) { create(:site_history, planning_application:) }
  let!(:planning_application_constraint) { create(:planning_application_constraint, planning_application:) }

  before do
    sign_in assessor
    planning_application.update!(constraints_checked: true)
  end

  it "displays application information navigation and section pages" do
    visit "/planning_applications/#{reference}/information"

    within ".govuk-service-navigation" do
      expect(page).to have_link("Overview", href: "/planning_applications/#{reference}/information")
      expect(page).to have_link("Documents (1)", href: "/planning_applications/#{reference}/information/documents")
      expect(page).to have_link("Constraints (1)", href: "/planning_applications/#{reference}/information/constraints")
      expect(page).to have_link("Consultees (0)", href: "/planning_applications/#{reference}/information/consultees")
      expect(page).to have_link("Neighbours (0)", href: "/planning_applications/#{reference}/information/neighbours")
      expect(page).to have_link("Site history (1)", href: "/planning_applications/#{reference}/information/site_history")
    end

    expect(page).to have_selector("h1", text: "Overview")
    expect(page).to have_selector("h2", text: "Application details")

    click_link "Documents (1)"

    expect(page).to have_current_path("/planning_applications/#{reference}/information/documents")
    expect(page).to have_selector("h1", text: "Documents")

    click_link "Constraints (1)"

    expect(page).to have_current_path("/planning_applications/#{reference}/information/constraints")
    expect(page).to have_selector("h1", text: "Constraints")

    click_link "Consultees (0)"

    expect(page).to have_current_path("/planning_applications/#{reference}/information/consultees")
    expect(page).to have_selector("h1", text: "Consultees")

    click_link "Neighbours (0)"

    expect(page).to have_current_path("/planning_applications/#{reference}/information/neighbours")
    expect(page).to have_selector("h1", text: "Neighbours")

    click_link "Site history (1)"

    expect(page).to have_current_path("/planning_applications/#{reference}/information/site_history")
    expect(page).to have_selector("h1", text: "Site history")
  end

  it "displays the documents content" do
    visit "/planning_applications/#{reference}/information/documents"

    expect(page).to have_selector(".govuk-button", text: "Download all documents")

    within(".govuk-tabs") do
      within("#all") do
        within(".govuk-table") do
          expect(page).to have_content("File name: #{document.name}")
          expect(page).not_to have_content("File name: #{document2.name}")
        end
      end
    end

    expect(page).to have_selector("h2", text: "Archived documents")
    within(".archived-documents") do
      expect(page).not_to have_content(document.name.to_s)
      expect(page).to have_content(document2.name.to_s)
    end
  end

  context "when the application is pre-application" do
    let(:planning_application) do
      create(
        :planning_application,
        :pre_application,
        :awaiting_determination,
        :with_preapp_assessment,
        local_authority:
      )
    end

    it "doesn't have Neighbours tab" do
      visit "/planning_applications/#{reference}/information"

      within ".govuk-service-navigation" do
        expect(page).to have_link("Overview", href: "/planning_applications/#{reference}/information")
        expect(page).to have_link("Documents (1)", href: "/planning_applications/#{reference}/information/documents")
        expect(page).to have_link("Constraints (3)", href: "/planning_applications/#{reference}/information/constraints")
        expect(page).to have_link("Consultees (0)", href: "/planning_applications/#{reference}/information/consultees")
        expect(page).not_to have_link("Neighbours (0)", href: "/planning_applications/#{reference}/information/neighbours")
        expect(page).to have_link("Site history (1)", href: "/planning_applications/#{reference}/information/site_history")
      end
    end
  end
end
