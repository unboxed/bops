# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add informatives" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  it "I can add informatives" do
    within("#add-informatives") do
      expect(page).to have_content "Not started"
      click_link "Add informatives"
    end

    expect(page).to have_content "Add informatives"
    expect(page).to have_content "No informatives added yet"

    fill_in "Enter a title", with: "Informative 1"
    fill_in "Enter details of the informative", with: "Consider the trees"

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"

    within("tr", text: "Informative 1") do
      expect(page).to have_content "Consider the trees"
    end

    fill_in "Enter a title", with: "Informative 2"
    fill_in "Enter details of the informative", with: "Consider the park"

    click_button "Add informative"

    within("tr", text: "Informative 2") do
      expect(page).to have_content "Consider the park"
    end

    # Check in progress
  end

  it "I can edit informatives" do
    informative = create(:informative, planning_application:)

    within("#add-informatives") do
      # expect(page).to have_content "Not started"
      click_link "Add informatives"
    end

    within("tr", text: informative.title) do
      expect(page).to have_content informative.text

      click_link "Edit"
    end

    expect(page).to have_content "Edit informative"

    fill_in "Enter a title", with: "My new title"
    fill_in "Enter details of the informative", with: "The new detail"

    click_button "Save informative"

    expect(page).to have_content "Informative successfully added"

    within("tr", text: "My new title") do
      expect(page).to have_content "The new detail"
    end
  end

  it "I can delete informatives" do
    informative = create(:informative, planning_application:)

    within("#add-informatives") do
      # expect(page).to have_content "Not started"
      click_link "Add informatives"
    end

    within("tr", text: informative.title) do
      expect(page).to have_content informative.text

      click_link "Remove"
    end

    expect(page).to have_content "Informative was successfully removed"
    expect(page).to have_content "No informatives added yet"
  end

  it "shows errors" do
    click_link "Add informatives"

    expect(page).to have_content "No informatives added yet"

    click_button "Add informative"

    expect(page).to have_content "Fill in the title of the informative"
    expect(page).to have_content "Fill in the text of the informative"

    fill_in "Enter a title", with: "My new title"
    fill_in "Enter details of the informative", with: "The new detail"

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"

    within("tr", text: "My new title") do
      expect(page).to have_content "The new detail"

      click_link "Edit"
    end

    expect(page).to have_content "Edit informative"

    fill_in "Enter a title", with: ""
    fill_in "Enter details of the informative", with: ""

    click_button "Save informative"

    expect(page).to have_content "Fill in the title of the informative"
    expect(page).to have_content "Fill in the text of the informative"

    fill_in "Enter a title", with: "My newer title"
    fill_in "Enter details of the informative", with: "The newer detail"

    click_button "Save informative"

    expect(page).to have_content "Informative successfully added"

    within("tr", text: "My newer title") do
      expect(page).to have_content "The newer detail"
    end
  end

  it "I can mark the task as complete" do
    informative = create(:informative, planning_application:)

    within("#add-informatives") do
      expect(page).to have_content "In progress"
      click_link "Add informatives"
    end

    click_button "Save and mark as complete"

    within("#add-informatives") do
      expect(page).to have_content "Complete"
    end
  end
end
