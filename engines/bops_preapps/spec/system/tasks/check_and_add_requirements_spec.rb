# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check and add requirements task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:, recommended_application_type:) }
  let(:user) { create(:user, local_authority:) }
  let!(:requirement) { create(:local_authority_requirement, local_authority:, category: "drawings", description: "Floor plans – existing") }
  let!(:requirement2) { create(:local_authority_requirement, local_authority:, category: "supporting_documents", description: "Parking plan") }
  let!(:requirement3) { create(:local_authority_requirement, local_authority:, category: "evidence", description: "Design statement") }
  let!(:recommended_application_type) { create(:application_type, :householder, local_authority:, requirements: [requirement]) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/check-and-add-requirements") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "displays the form to add requirements when none have been added" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    expect(page).to have_content("Check and add requirements")
    expect(page).to have_content("Add requirements")
    expect(page).to have_css(".govuk-summary-card")
    expect(page).to have_content("No requirements of this type selected")
    expect(page).to have_button("Save and mark as complete")
  end

  it "shows summary cards and edit/remove links for existing requirements" do
    planning_application.add_requirements([requirement2, requirement3])

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    within("#supporting_documents-card") do
      expect(page).to have_content("Parking plan")
      expect(page).to have_link("Edit")
      expect(page).to have_link("Remove")
    end

    within("#evidence-card") do
      expect(page).to have_content("Design statement")
      expect(page).to have_link("Edit")
      expect(page).to have_link("Remove")
    end

    expect(page).to have_button("Save and mark as complete")
    expect(page).to have_button("Save changes")
  end

  it "updates the task status when save buttons are clicked" do
    planning_application.add_requirements([requirement3])

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    expect(task).to be_not_started

    click_button "Save changes"

    expect(page).to have_content("Requirements were successfully saved")
    expect(task.reload).to be_in_progress

    click_button "Save and mark as complete"

    expect(page).to have_content("Requirements were successfully saved")
    expect(task.reload).to be_completed
  end

  it "hides save buttons when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    expect(page).not_to have_button("Save and mark as complete")
    expect(page).not_to have_button("Save draft")
  end

  it "redirects back to task page after adding requirements" do
    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    click_button "Add requirements"

    click_link "Supporting documents"
    check "Parking plan"
    click_button "Add requirements"

    expect(page).to have_content("Check and add requirements")
    expect(page).to have_content("Requirements successfully added")
    within("#supporting_documents-card") do
      expect(page).to have_content("Parking plan")
    end
  end

  it "redirects back to task page after editing a requirement" do
    planning_application.add_requirements([requirement2])

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    within("#supporting_documents-card") do
      click_link "Edit"
    end

    expect(page).to have_content("Edit requirement")
    fill_in "Guidelines URL", with: "https://example.com/guidelines"
    click_button "Save"

    expect(page).to have_content("Check and add requirements")
    expect(page).to have_content("Requirement successfully updated")
  end

  it "redirects back to task page after removing a requirement", :js do
    planning_application.add_requirements([requirement2, requirement3])

    within ".bops-sidebar" do
      click_link "Check and add requirements"
    end

    within("#supporting_documents-card") do
      accept_confirm do
        click_link "Remove"
      end
    end

    expect(page).to have_content("Check and add requirements")
    expect(page).to have_content("Requirement successfully removed")

    within("#supporting_documents-card") do
      expect(page).not_to have_content("Parking plan")
      expect(page).to have_content("No requirements of this type selected")
    end

    within("#evidence-card") do
      expect(page).to have_content("Design statement")
    end
  end

  it "raises an error when attempting to redirect to external URLs" do
    planning_application.add_requirements([requirement])
    added_requirement = planning_application.requirements.first

    visit "/planning_applications/#{planning_application.reference}/assessment/requirements/#{added_requirement.id}/edit?redirect_to=https://phising.com/"

    fill_in "Guidelines URL", with: "https://example.com/test"

    expect {
      click_button "Save"
    }.to raise_error(ActionController::Redirecting::UnsafeRedirectError)
  end
end
