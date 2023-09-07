# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constraints" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority, api_user:)
  end

  before do
    sign_in assessor
    visit planning_application_constraints_path(planning_application)
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

      within(".govuk-heading-m") do
        expect(page).to have_text("Constraints identified by PlanX")
      end

      within("#constraints-review") do
        expect(page).to have_text("Review the following constraints and update as necessary.")
      end

      expect(page).to have_link("Back", href: planning_application_validation_tasks_path(planning_application))

      click_button "Marked as checked"

      expect(page).to have_text("Constraints was successfully checked.")

      expect(page).to have_link(
        "Check constraints",
        href: planning_application_constraints_path(planning_application)
      )
      within("#constraints-validation-tasks .govuk-tag--green") do
        expect(page).to have_content("Checked")
      end

      visit planning_application_audits_path(planning_application)

      expect(page).to have_text("Constraints Checked")
    end
  end

  context "when adding constraints" do
    before do
      Rails.application.load_seed

      click_link "Update constraints"
    end

    it "I can check/uncheck constraints and add local constraints" do
      check "Flood zone"
      check "Site of Special Scientific Interest (SSSI)"
      check "National Park"

      fill_in "planning_application[constraint_type]", with: "local constraint"

      click_button "Save"

      within(".govuk-list") do
        expect(page).to have_text("Flood zone")
        expect(page).to have_text("Site of Special Scientific Interest (SSSI)")
        expect(page).to have_text("National Park")
        expect(page).to have_text("Local Constraint")
      end

      expect(planning_application.constraints.length).to eq(4)
      expect(planning_application.planning_application_constraints.length).to eq(4)

      click_link "Update constraints"

      uncheck "Flood zone"
      uncheck "Site of Special Scientific Interest (SSSI)"

      click_button "Save"

      within(".govuk-list") do
        expect(page).not_to have_text("Flood zone")
        expect(page).not_to have_text("Site of Special Scientific Interest (SSSI)")
        expect(page).to have_text("National Park")
        expect(page).to have_text("Local Constraint")
      end

      planning_application.reload
      expect(planning_application.constraints.length).to eq(2)
      expect(planning_application.planning_application_constraints.length).to eq(2)

      visit planning_application_audits_path(planning_application)
      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Site of Special Scientific Interest (SSSI)")
        expect(page).to have_content("Constraint removed")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when there is an error with saving a new local constraint" do
      before do
        allow_any_instance_of(Constraint).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "presents an error message to the user and does not persist any updates" do
        check "Flood zone"
        fill_in "planning_application[constraint_type]", with: "local constraint"

        click_button "Save"

        expect(page).to have_content("Couldn't update constraints with error: Record invalid. Please contact support.")

        planning_application.reload
        expect(planning_application.constraints.length).to eq(0)
        expect(planning_application.planning_application_constraints.length).to eq(0)
      end
    end

    context "when there is an error with saving a planning application constraint" do
      before do
        allow_any_instance_of(PlanningApplicationConstraint).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "presents an error message to the user and does not persist any updates" do
        check "Flood zone"

        click_button "Save"

        expect(page).to have_content("Couldn't update constraints with error: Record invalid. Please contact support.")

        planning_application.reload
        expect(planning_application.constraints.length).to eq(0)
        expect(planning_application.planning_application_constraints.length).to eq(0)
      end
    end

    context "when there is an error with destroying the removed constraints" do
      before do
        allow_any_instance_of(PlanningApplicationConstraint).to receive(:destroy).and_raise(ActiveRecord::RecordInvalid)
      end

      it "presents an error message to the user and does not persist any updates" do
        check "Flood zone"
        click_button "Save"
        click_link "Update constraints"
        uncheck "Flood zone"
        check "Site of Special Scientific Interest (SSSI)"
        check "National Park"
        click_button "Save"

        expect(page).to have_content("Couldn't update constraints with error: Record invalid. Please contact support.")

        planning_application.reload
        expect(planning_application.constraints.length).to eq(1)
        expect(planning_application.planning_application_constraints.length).to eq(1)
      end
    end
  end
end
