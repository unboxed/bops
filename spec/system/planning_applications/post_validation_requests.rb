# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validation tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  before do
    sign_in assessor

    visit planning_application_path(planning_application)
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create :planning_application, :in_assessment, local_authority: default_local_authority
    end

    it "displays the post validation request table" do
      within("#assessment-section") do
        click_link("Review non-validation requests")
      end

      within(".validation-requests-table") do
        expect(page).to have_content("Post-validation requests")
      end
    end

    context "when viewing the post validation requests table" do
      let!(:planning_application) do
        create :planning_application, :invalidated, local_authority: default_local_authority
      end

      before do
        create(:red_line_boundary_change_validation_request, :closed, planning_application: planning_application)
        create(:red_line_boundary_change_validation_request, :cancelled, planning_application: planning_application)

        planning_application.start!

        visit post_validation_requests_planning_application_validation_requests_path(planning_application)
      end

      it "does not display any pre validation requests" do
        expect(page).not_to have_content("Red line boundary changes")
        expect(page).not_to have_content("View request red line boundary")
        expect(page).not_to have_content("Cancelled requests")

        # check pre valiation requests table
        visit planning_application_validation_requests_path(planning_application)
        within(".validation-requests-table") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("View request red line boundary")
        end

        within(".cancelled-requests") do
          expect(page).to have_content("Red line boundary changes")
        end
      end
    end

    context "when viewing the pre validation requests table" do
      let!(:planning_application) do
        create :planning_application, :in_assessment, local_authority: default_local_authority
      end

      before do
        create(:red_line_boundary_change_validation_request, :closed, planning_application: planning_application)
        create(:red_line_boundary_change_validation_request, :cancelled, planning_application: planning_application)

        create(
          :description_change_validation_request,
          :cancelled,
          planning_application: planning_application,
          proposed_description: "New description 1"
        )

        create(
          :description_change_validation_request,
          planning_application: planning_application,
          proposed_description: "New description 2"
        )

        visit planning_application_validation_requests_path(planning_application)
      end

      it "does not display any post validation requests" do
        expect(page).not_to have_content("Red line boundary changes")
        expect(page).not_to have_content("View request red line boundary")
        expect(page).not_to have_content("Cancelled requests")
        expect(page).not_to have_content("New description 1")
        expect(page).not_to have_content("New description 2")

        # check post valiation requests table
        visit post_validation_requests_planning_application_validation_requests_path(planning_application)
        within(".validation-requests-table") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("View request red line boundary")
          expect(page).to have_content("New description 2")
        end

        within(".cancelled-requests") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("New description 1")
        end
      end
    end
  end

  context "when application is not started" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: default_local_authority
    end

    it "does not allow you to view post validation requests" do
      expect(page).not_to have_link("Review non-validation requests")

      # visit url directly
      visit post_validation_requests_planning_application_validation_requests_path(planning_application)
      expect(page).to have_content("forbidden")
    end
  end

  context "when application is invalidated" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: default_local_authority
    end

    it "does not allow you to view post validation requests" do
      expect(page).not_to have_link("Review non-validation requests")

      # visit url directly
      visit post_validation_requests_planning_application_validation_requests_path(planning_application)
      expect(page).to have_content("forbidden")
    end
  end
end
