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
      visit "/planning_applications/#{planning_application.id}/validation/tasks"
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
        href: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/made"
      )
    end

    it "displays the proposal details" do
      expect(page).to have_button("Proposal details")
    end

    it "I can mark the legislative requirements as checked" do
      click_button "Mark as checked"

      expect(page).to have_content("Legislative requirements have been marked as checked.")

      within("#check-legislative-requirements") do
        expect(page).to have_content("Checked")
      end

      click_link "Application"

      # Check audit logs
      click_button "Audit log"
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
        click_button "Mark as checked"

        expect(page).to have_content("Couldn't mark legislative requirements as checked - please contact support.")

        within("#check-legislative-requirements") do
          expect(page).to have_content("Not started")
        end
      end
    end
  end

  context "when planning application type has no legislation en.yml translation details" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.id}/validation/tasks"
    end

    it "does not show the check legislation tasklist" do
      expect(page).not_to have_css("#check-legislative-requirements")
    end

    it "shows forbidden when navigating to the page directly" do
      visit "/planning_applications/#{planning_application.id}/validation/legislation"
      expect(page).to have_content("Not found")
    end
  end
end
