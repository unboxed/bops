# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check legislation" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "when planning application type is prior approval 1A" do
    let!(:planning_application) do
      create(:planning_application, :prior_approval, :not_started, local_authority: default_local_authority)
    end

    before do
      planning_application.application_type.update(part: 1, section: "A")

      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link("Check legislative requirements")
    end

    it "displays the application information" do
      within("#planning-application-details") do
        expect(page).to have_content("Check legislative requirements")
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.description)
      end

      expect(page).to have_link(
        "Back",
        href: planning_application_validation_tasks_path(planning_application)
      )
    end

    it "displays the legislation information" do
      expect(page).to have_content("Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 1, Class A.")
      expect(page).to have_link(
        "The Town and Country Planning (General Permitted Development) (England) Order 2015",
        href: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2"
      )
    end

    it "displays the proposal details" do
      expect(page).to have_element("span", text: "Proposal details")
    end

    it "I can mark the legislative requirements as checked" do
      click_button "Save and mark as complete"

      expect(page).to have_content("Legislative requirements have been marked as checked.")

      within("#check-legislation-description-task") do
        expect(page).to have_content("Completed")
      end

      click_link "Application"

      # Check audit logs
      find("#audit-log").click
      click_link "View all audits"
      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Legislative requirements checked")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when there is an ActiveRecord Error" do
      before { allow_any_instance_of(PlanningApplication).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }

      it "present an error message" do
        click_button "Save and mark as complete"

        expect(page).to have_content("Couldn't mark legislative requirements as checked - please contact support.")

        within("#check-legislation-description-task") do
          expect(page).to have_content("Not started")
        end
      end
    end
  end

  context "when planning application type has no legislation details" do
    let(:config) { create(:application_type_config, :pre_application, :inactive, :without_legislation) }
    let(:application_type) { create(:application_type, config:, local_authority: default_local_authority) }
    let(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority, application_type:)
    end

    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "does not show the check legislation tasklist" do
      expect(page).not_to have_css("#check-legislation-description-task")
    end

    it "redirects to validation tasks page when navigating to the page directly" do
      visit "/planning_applications/#{planning_application.reference}/validation/legislation"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end
  end

  context "when legislative requirements feature is disabled" do
    let!(:planning_application) do
      create(:planning_application, :not_started, :pre_application, local_authority: default_local_authority)
    end

    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "does not have a section to check legislative requirements" do
      visit "planning_applications/#{planning_application.reference}/validation/tasks"

      expect(page).not_to have_content("Check legislative requirements")

      visit "planning_applications/#{planning_application.reference}/validation/legislation"

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end
  end
end
