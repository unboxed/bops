# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check if proposal is development task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:planning_application) do
    create(:planning_application, :lawfulness_certificate, :in_assessment, local_authority:)
  end
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/assess-against-legislation/check-if-proposal-is-development"
    )
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "shows the task in the sidebar" do
    within ".bops-sidebar" do
      expect(page).to have_link("Check if proposal is development")
    end
  end

  it "navigates to the task from the sidebar" do
    within ".bops-sidebar" do
      click_link "Check if proposal is development"
    end

    expect(page).to have_content("Is this proposal 'development' under Section 55 of the Town and Country Planning Act 1990?")
  end

  it "shows a validation error when no option is selected" do
    within ".bops-sidebar" do
      click_link "Check if proposal is development"
    end

    click_button "Save and mark as complete"

    within(".govuk-error-summary") do
      expect(page).to have_content("Select whether the application is development.")
    end
    expect(task.reload).to be_not_started
  end

  it "saves and completes when 'Yes' is selected" do
    within ".bops-sidebar" do
      click_link "Check if proposal is development"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Section 55 development was successfully updated")
    expect(task.reload).to be_completed
    expect(planning_application.reload.section_55_development).to be(true)
  end

  it "saves and completes when 'No' is selected" do
    within ".bops-sidebar" do
      click_link "Check if proposal is development"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Section 55 development was successfully updated")
    expect(task.reload).to be_completed
    expect(planning_application.reload.section_55_development).to be(false)
  end

  context "when section_55_development has previously been set" do
    let(:planning_application) do
      create(:planning_application, :lawfulness_certificate, :in_assessment, local_authority:, section_55_development: true)
    end

    it "pre-populates the form with the existing value" do
      within ".bops-sidebar" do
        click_link "Check if proposal is development"
      end

      expect(page).to have_field("Yes", checked: true)
      expect(page).to have_field("No", checked: false)
    end
  end

  context "when policy classes exist and 'No' is selected" do
    let!(:policy_class) { create(:policy_class) }
    let!(:planning_application_policy_class) do
      create(:planning_application_policy_class, planning_application:, policy_class:)
    end

    it "destroys the policy classes" do
      expect {
        within ".bops-sidebar" do
          click_link "Check if proposal is development"
        end

        choose "No"
        click_button "Save and mark as complete"
      }.to change { planning_application.planning_application_policy_classes.count }.from(1).to(0)

      expect(task.reload).to be_completed
    end
  end

  context "when policy classes exist and 'Yes' is selected" do
    let!(:policy_class) { create(:policy_class) }
    let!(:planning_application_policy_class) do
      create(:planning_application_policy_class, planning_application:, policy_class:)
    end

    it "does not destroy the policy classes" do
      expect {
        within ".bops-sidebar" do
          click_link "Check if proposal is development"
        end

        choose "Yes"
        click_button "Save and mark as complete"
      }.not_to change { planning_application.planning_application_policy_classes.count }

      expect(task.reload).to be_completed
    end
  end
end
