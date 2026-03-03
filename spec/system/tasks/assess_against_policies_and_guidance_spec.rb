# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess against policies and guidance task", type: :system, js: true do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :validation_requests_ro, local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let(:consideration_set) { planning_application.consideration_set }
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance"
    )
  end

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)
    create(:local_authority_policy_area, local_authority:, description: "Design")
    create(:local_authority_policy_area, local_authority:, description: "Environment")
    create(:local_authority_policy_reference, local_authority:, code: "PP100", description: "Wall materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP101", description: "Roofing materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP200", description: "Flood risk")
    create(:local_authority_policy_guidance, local_authority:, description: "Design Guidance")
    create(:local_authority_policy_guidance, local_authority:, description: "Environmental Guidance")

    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "shows errors when required fields are missing" do
    within ".bops-sidebar" do
      click_link "Assess against policies and guidance"
    end

    click_button "Add consideration"

    within "div[role=alert]" do
      expect(page).to have_content("Enter the policy area of this consideration")
      expect(page).to have_content("Enter the assessment of this consideration")
      expect(page).to have_content("Enter the conclusion for this consideration")
    end
  end

  it "adds a consideration and saves as complete" do
    within ".bops-sidebar" do
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("No considerations added yet")

    fill_in "Enter policy area", with: "Design"
    pick "Design", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Wall"
    pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy guidance", with: "Design"
    pick "Design Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Uses red brick with grey slates"
    fill_in "Enter conclusion", with: "Complies with design guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Policy area assessment successfully added")
    expect(page).to have_no_selector("details[open]")

    click_button "Save and mark as complete"

    expect(page).to have_content("Add, edit and sort considerations")

    expect(task.reload).to be_completed
  end

  it "saves progress as a draft" do
    within ".bops-sidebar" do
      click_link "Assess against policies and guidance"
    end

    fill_in "Enter policy area", with: "Design"
    pick "Design", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Wall"
    pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter assessment", with: "Uses red brick with grey slates"
    fill_in "Enter conclusion", with: "Complies with design guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Policy area assessment successfully added")

    click_button "Save changes"

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance")
    expect(page).to have_content("Add, edit and sort considerations")
    expect(task.reload).to be_in_progress
  end

  context "when a consideration exists" do
    let!(:consideration) do
      create(:consideration,
        consideration_set:,
        policy_area: "Design",
        assessment: "Original assessment text",
        conclusion: "Original conclusion text")
    end

    before do
      within ".bops-sidebar" do
        click_link "Assess against policies and guidance"
      end
    end

    it "edits a consideration and redirects back to the task show page" do
      within "#consideration_#{consideration.id}" do
        click_link "Edit"
      end

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance/#{consideration.id}/edit")

      expect(page).to have_content("Edit consideration")

      fill_in "Enter assessment", with: "Updated assessment text"
      click_button "Save consideration"

      expect(page).to have_content("Policy area assessment successfully added")
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance")
      expect(page).to have_selector("h1", text: "Assess against policies and guidance")

      within "#consideration_#{consideration.id}" do
        click_button "Show more"
        expect(page).to have_selector("dd", text: "Updated assessment text")
      end
    end

    it "removes a consideration and redirects back to the task show page" do
      within "#consideration_#{consideration.id}" do
        accept_confirm do
          click_link "Remove"
        end
      end

      expect(page).to have_content("Consideration was successfully removed")
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/assess-against-policies-and-guidance/assess-against-policies-and-guidance")
      expect(page).to have_selector("h1", text: "Assess against policies and guidance")
      expect(page).not_to have_selector("h2", text: "Design")
    end
  end
end
