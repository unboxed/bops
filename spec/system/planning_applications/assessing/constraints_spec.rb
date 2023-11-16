# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constraints" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, name: "Robert", local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, :with_constraints, local_authority: default_local_authority, api_user:)
  end

  before do
    Rails.application.load_seed
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation/constraints"
  end

  it "displays the planning application address and reference" do
    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  context "when application is not started or invalidated" do
    it "displays the constraints" do
      within(".govuk-heading-l") do
        expect(page).to have_text("Check the constraints")
      end

      within("#planx") do
        expect(page).to have_text("Constraints suggested by: PlanX (2)")
      end

      within(".planx-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
      end

      within("#accordion-with-other-constraints-sections-heading-1") do
        expect(page).to have_text("Other constraints")
      end

      within(".other-constraints-table") do
        expect(page).not_to have_text("Conservation area")
        expect(page).not_to have_text("Listed building outline")
      end

      click_button "Other constraints"

      expect(page).to have_link("Back", href: planning_application_validation_tasks_path(planning_application))

      click_button "Save and mark as checked"

      expect(page).to have_text("Constraints was successfully checked")

      expect(page).to have_link(
        "Check constraints",
        href: planning_application_validation_constraints_path(planning_application)
      )
      within("#constraints-validation-tasks .govuk-tag--green") do
        expect(page).to have_content("Checked")
      end

      visit "/planning_applications/#{planning_application.id}/audits"

      expect(page).to have_text("Constraints Checked")
    end
  end

  context "when adding constraints" do
    it "I can check/uncheck constraints" do
      within(".planx-constraints-table") do
        find_checkbox_by_id("constraint_id_#{planning_application.planning_application_constraints.first.constraint_id}").click
      end

      click_button "Other constraints"

      find_checkbox_by_id("constraint_id_#{Constraint.find_by(type: "monument").id}").click
      find_checkbox_by_id("constraint_id_#{Constraint.find_by(type: "nature_asnw").id}").click

      click_button "Save and mark as checked"

      visit "/planning_applications/#{planning_application.id}/validation/constraints"

      within("#planx") do
        expect(page).to have_text("Constraints suggested by: PlanX (2)")
      end

      within(".planx-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
      end

      within("#robert") do
        expect(page).to have_text("Constraints suggested by: Robert (2)")
      end

      within(".robert-constraints-table") do
        expect(page).to have_text("Scheduled monument")
        expect(page).to have_text("Ancient woodland")
      end

      within("#accordion-with-other-constraints-sections-heading-1") do
        expect(page).to have_text("Other constraints")
      end

      click_button "Other constraints"

      within(".other-constraints-table") do
        expect(page).not_to have_text("Conservation area")
        expect(page).not_to have_text("Listed building outline")
        expect(page).not_to have_text("Scheduled monument")
        expect(page).not_to have_text("Ancient woodland")
      end

      expect(planning_application.planning_application_constraints.active.length).to eq(3)
      expect(planning_application.planning_application_constraints.length).to eq(4)

      visit "/planning_applications/#{planning_application.id}/audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Constraints Checked")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when there is an error with saving a planning application constraint" do
      before do
        allow_any_instance_of(PlanningApplicationConstraint).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "presents an error message to the user and does not persist any updates" do
        within(".planx-constraints-table") do
          find_checkbox_by_id("constraint_id_#{planning_application.planning_application_constraints.first.constraint_id}").click
        end

        click_button "Save and mark as checked"

        expect(page).to have_content("Couldn't update constraints with error: Record invalid. Please contact support.")

        planning_application.reload
        expect(planning_application.constraints.length).to eq(2)
        expect(planning_application.planning_application_constraints.length).to eq(2)
      end
    end
  end
end
