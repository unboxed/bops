# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constraints" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
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

      expect(page).to have_text("Identified constraints")

      within(".identified-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
      end

      find("span", text: "Add constraints").click

      within(".other-constraints-table") do
        expect(page).not_to have_text("Conservation area")
        expect(page).not_to have_text("Listed building outline")
      end

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
    it "I can add/remove constraints" do
      within(".identified-constraints-table") do
        expect(page).not_to have_link("Remove")
      end

      find("span", text: "Add constraints").click

      within(".other-constraints-table") do
        within(row_with_content("Scheduled monument")) do
          click_link "Add"
        end
      end

      find("span", text: "Add constraints").click

      within(".other-constraints-table") do
        within(row_with_content("Special area of conservation")) do
          click_link "Add"
        end
      end

      within(".identified-constraints-table") do
        expect(page).to have_content "Scheduled monument"
        expect(page).to have_content "Special area of conservation"
      end

      click_button "Save and mark as checked"

      visit "/planning_applications/#{planning_application.id}/validation/constraints"

      within(".identified-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
        expect(page).to have_text("Scheduled monument")
        expect(page).to have_text("Special area of conservation")
      end

      find("span", text: "Add constraints").click

      within(".other-constraints-table") do
        expect(page).not_to have_text("Conservation area")
        expect(page).not_to have_text("Listed building outline")
        expect(page).not_to have_text("Scheduled monument")
        expect(page).not_to have_text("Special area of conservation")
      end

      within(".identified-constraints-table") do
        within(row_with_content("Special area of conservation")) do
          click_link "Remove"
        end
      end

      within(".identified-constraints-table") do
        expect(page).not_to have_text("Special area of conservation")
      end

      find("span", text: "Add constraints").click

      within(".other-constraints-table") do
        expect(page).to have_text("Special area of conservation")
      end

      visit "/planning_applications/#{planning_application.id}/audits"

      within("#audit_#{Audit.last.id - 1}") do
        expect(page).to have_content("Constraints Checked")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Constraint removed")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when there is an error with saving a planning application constraint" do
      before do
        allow_any_instance_of(PlanningApplicationConstraint).to receive(:save!).and_return(false)
      end

      it "presents an error message to the user and does not persist any updates" do
        find("span", text: "Add constraints").click

        within(".other-constraints-table") do
          within(row_with_content("Scheduled monument")) do
            click_link "Add"
          end
        end

        expect(page).to have_content("Couldn't add constraint - please contact support.")

        planning_application.reload
        expect(planning_application.constraints.length).to eq(2)
        expect(planning_application.planning_application_constraints.length).to eq(2)
      end
    end
  end
end
