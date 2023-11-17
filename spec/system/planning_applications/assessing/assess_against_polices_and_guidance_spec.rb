# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assess against policies and guidance" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let(:local_authority) { create(:local_authority, :default) }

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

    expect(page).to have_content "Design"
    expect(page).to have_content "Impact on neighbours"
    expect(page).to have_content "Other"

    check "Design"
    within("#local-policy-local-policy-areas-attributes-0-areas-design-conditional") do
      fill_in "Which policies are relevant", with: "Q1, Q2"
      choose "Yes"
      fill_in "Which guidance? (e.g. the design code)", with: "P1, P2"
      fill_in "Enter your assessment", with: "It's all fine"
    end

    check "Other"
    within("#local-policy-local-policy-areas-attributes-2-areas-other-conditional") do
      fill_in "Which policies are relevant", with: "S1, S2"
      choose "No"
    end

    click_button "Save and come back later"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "In progress"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Assess against policies and guidance")

    within("#local-policy-local-policy-areas-attributes-2-areas-other-conditional") do
      fill_in "Enter your assessment", with: "It's also all fine"
    end

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

    check "Design"
    within("#local-policy-local-policy-areas-attributes-0-areas-design-conditional") do
      fill_in "Which policies are relevant", with: "Q1, Q2"
      choose "Yes"
      fill_in "Which guidance? (e.g. the design code)", with: "P1, P2"
      fill_in "Enter your assessment", with: "It's all fine"
    end

    check "Other"
    within("#local-policy-local-policy-areas-attributes-2-areas-other-conditional") do
      fill_in "Which policies are relevant", with: "S1, S2"
      choose "No"
      fill_in "Enter your assessment", with: "It's also all fine"
    end

    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Design")
    expect(page).to have_content("Q1, Q2")
    expect(page).to have_content("P1, P2")
    expect(page).to have_content("It's all fine")
    expect(page).to have_content("Other")
    expect(page).to have_content("S1, S2")
    expect(page).to have_content("It's also all fine")

    expect(page).not_to have_content("Save and mark as complete")

    click_link "Edit Assess against policies and guidance"

    within("#local-policy-local-policy-areas-attributes-0-areas-design-conditional") do
      fill_in "Which policies are relevant", with: "Q1, Q2, Q3"
    end

    click_button "Save and mark as complete"

    within("#assess-against-legislation-tasks") do
      expect(page).to have_content "Completed"
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_content("Q1, Q2, Q3")
  end

  it "shows errors" do
    click_link "Assess against policies and guidance"

    click_button "Save and mark as complete"

    expect(page).to have_content("Local policy areas can't be blank ")

    click_button "Save and come back later"

    expect(page).to have_content("Check against policy and guidance response was sucessfully created")
  end
end
