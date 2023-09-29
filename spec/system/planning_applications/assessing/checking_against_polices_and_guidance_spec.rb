# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking against policies and guidance" do
  let(:local_authority) { create(:local_authority, :default) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :in_assessment,
      :with_constraints,
      local_authority:
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
    visit planning_application_assessment_tasks_path(planning_application)
  end

  it "allows officer to assess against policies and guidance" do
    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Not started"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Assess against policies and guidance")

    fill_in "Which local policies and guidance did you assess against?", with: "Policy 1, Policy 2"
    fill_in "What is your assessment of those policies?", with: "This application meets those"

    click_button "Save and come back later"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "In progress"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Assess against policies and guidance")

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

    fill_in "Which local policies and guidance did you assess against?", with: "Policy 1, Policy 2"
    fill_in "What is your assessment of those policies?", with: "This application meets those"

    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Policy 1, Policy 2")
    expect(page).to have_content("This application meets those")

    expect(page).not_to have_content("Save and mark as complete")

    click_link "Edit Assess against policies and guidance"

    fill_in "Which local policies and guidance did you assess against?", with: "Policy 1, Policy 2, Policy 3"
    fill_in "What is your assessment of those policies?", with: "This application meets those really"

    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Policy 1, Policy 2, Policy 3")
    expect(page).to have_content("This application meets those really")
  end

  it "shows errors" do
    click_link "Assess against policies and guidance"

    click_button "Save and mark as complete"

    expect(page).to have_content("Policies can't be blank")
    expect(page).to have_content("Assessment can't be blank")

    click_button "Save and come back later"

    expect(page).to have_content("Check against policy and guidance response was sucessfully created")
  end
end
