# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation requirement", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  context "when the planning application is a pre-application" do
    let(:application_type) { create(:application_type, :pre_application, local_authority:) }
    let(:planning_application) do
      create(
        :planning_application,
        :with_boundary_geojson,
        :published,
        local_authority:,
        application_type:
      )
    end

    let!(:consultation) do
      planning_application.consultation || planning_application.create_consultation!
    end

    before do
      sign_in assessor
    end

    it "locks tasks until answered and reflects the chosen requirement" do
      visit "/planning_applications/#{planning_application.reference}/consultation"

      within ".bops-sidebar" do
        expect(page).to have_link("Determine consultation requirement")
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
      expect(consultation.reload).to be_in_progress

      within ".bops-sidebar" do
        expect(page).to have_link("Determine consultation requirement")
        expect(page).to have_link("Add and assign consultees")
        expect(page).to have_link("Send emails to consultees")
        expect(page).to have_link("View consultee responses")
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")

      within ".bops-sidebar" do
        expect(page).to have_link("Determine consultation requirement")
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end
    end

    it "warns and removes consultees when changing to not required" do
      planning_application.update!(consultation_required: true)
      create(:consultee, consultation:)

      visit "/planning_applications/#{planning_application.reference}/consultation_requirement/edit"
      expect(page).to have_selector(
        ".govuk-warning-text",
        text: "Changing this answer to \"No\" will remove all consultees"
      )

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
    end
  end

  context "when the planning application is not a pre-application" do
    let(:application_type) { create(:application_type, :planning_permission, local_authority:) }
    let(:planning_application) do
      create(
        :planning_application,
        :with_boundary_geojson,
        :published,
        local_authority:,
        application_type:
      )
    end

    before do
      planning_application.consultation || planning_application.create_consultation!
      sign_in assessor
    end

    it "keeps consultation tasks available without the gate" do
      visit "/planning_applications/#{planning_application.reference}/consultation"

      within "#consultee-tasks" do
        expect(page).not_to have_link("Determine if consultation is required")

        within "li:nth-child(1)" do
          expect(page).to have_link("Add and assign consultees")
          expect(page).to have_selector(".govuk-tag", text: "Not started")
        end

        within "li:nth-child(2)" do
          expect(page).to have_link("Send emails to consultees")
          expect(page).to have_selector(".govuk-tag", text: "Not started")
        end

        within "li:nth-child(3)" do
          expect(page).to have_text("View consultee responses")
          expect(page).to have_selector(".govuk-tag", text: "Not started")
          expect(page).to have_link("View consultee responses")
        end
      end
    end
  end
end
