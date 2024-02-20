# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assess against policies and guidance" do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :in_assessment,
      :with_constraints,
      local_authority:,
      api_user:
    )
  end

  let(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Alice Smith"
    )
  end

  before do
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.id}/assessment/tasks"
  end

  it "allows officer to assess against policies and guidance" do
    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Not started"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Assess against policies and guidance")

    expect(page).to have_content "You have not added any considerations"

    click_link "Add new consideration"

    expect(page).to have_content("Create a new consideration")

    choose "policy-2"
    fill_in "manual-policy-input", with: "Consistency with local architecture"

    fill_in "Which policies are relevant", with: "P2, P3"

    choose "No"

    fill_in "Enter your assessment", with: "It appears to meet these criteria"

    click_button "Add consideration"

    expect(page).to have_content("Assess against policies and guidance")
    expect(page).to have_content("Consistency with local architecture")
    expect(page).to have_content("P2, P3")
    expect(page).to have_content("It appears to meet these criteria")

    click_link "Back"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "In progress"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Assess against policies and guidance")
    expect(page).to have_content("Consistency with local architecture")

    click_link("Consistency with local architecture")
    click_link("Edit consideration")

    fill_in "Enter your assessment", with: "It's also all fine"

    click_button "Update consideration"
    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
    end
  end

  it "allows officer to edit assess against policies and guidance" do
    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Not started"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content "You have not added any considerations"

    click_link "Add new consideration"

    expect(page).to have_content("Add a custom policy area if it does not appear in the list above")

    choose "policy-2"
    fill_in "manual-policy-input", with: "Consistency with local architecture"

    fill_in "Which policies are relevant", with: "P2, P3"

    choose "No"

    fill_in "Enter your assessment", with: "It appears to meet these criteria"

    click_button "Add consideration"

    expect(page).to have_content("Assess against policies and guidance")

    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Consistency with local architecture")
    expect(page).to have_content("P2, P3")
    expect(page).to have_content("It appears to meet these criteria")

    expect(page).not_to have_content("Save and mark as complete")

    click_link "Edit Assess against policies and guidance"

    click_link "Consistency with local architecture"
    click_link "Edit consideration"

    fill_in "Which policies are relevant", with: "Q1, Q2, Q3"

    click_button "Update consideration"
    click_link "Back"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Q1, Q2, Q3")
  end

  it "shows errors" do
    click_link "Assess against policies and guidance"

    expect(page).to have_content "You have not added any considerations"

    click_link "Add new consideration"

    click_button "Add consideration"

    expect(page).to have_content("There is a problem")
  end
end
