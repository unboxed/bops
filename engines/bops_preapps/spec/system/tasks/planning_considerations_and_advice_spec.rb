# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning considerations and advice task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path! "check-and-assess/assessment-summaries/planning-considerations-and-advice" }

  let!(:policy_area) { create(:local_authority_policy_area, local_authority:, description: "Environment") }
  let!(:policy_reference) { create(:local_authority_policy_reference, local_authority:, code: "PP200", description: "Flood risk") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

    within ".bops-sidebar" do
      click_link "Planning considerations and advice"
    end
  end

  it "Can complete and submit the form" do
    click_button "Confirm as checked"

    expect(task.status).to eq "completed"
  end

  it "Can add a consideration", :capybara do
    fill_in "Select policy area", with: policy_area.description
    click_button "Add consideration"

    toggle("Add advice")

    fill_in "Enter element of proposal", with: "Things"
    fill_in "Enter policy reference", with: policy_reference.description
    pick "#{policy_reference.code} - #{policy_reference.description}", from: "#policyReferencesAutoComplete"
    choose "Complies"

    fill_in_rich_text_area "Advice", with: "OK"

    click_button "Save advice"

    expect(page).not_to have_text "Failed to add consideration"

    click_button "Confirm as checked"

    expect(planning_application.consideration_set.considerations).not_to be_empty
    expect(task.status).to eq "completed"
    consideration = planning_application.consideration_set.considerations.last
    expect(consideration.policy_area).to eq policy_area.description
    expect(consideration.policy_references.map(&:description)).to contain_exactly(policy_reference.description)
    expect(consideration.summary_tag).to eq "complies"
  end

  it "Can't add consideration without area" do
    click_button "Add consideration"

    expect(page).to have_text "Failed to add consideration"

    expect(planning_application.consideration_set.considerations).to be_empty
    expect(task.status).to eq "not_started"
  end

  it "Can't add incomplete advice", :capybara do
    fill_in "Select policy area", with: policy_area.description
    click_button "Add consideration"

    toggle("Add advice")

    fill_in "Enter element of proposal", with: "Things"
    # mandatory policy reference left blank
    choose "Complies"

    click_button "Save advice"

    expect(page).to have_text "Failed to add consideration"

    expect(planning_application.consideration_set.considerations).not_to be_empty
    expect(task.status).to eq "not_started"
    consideration = planning_application.consideration_set.considerations.last
    expect(consideration.summary_tag).to be_nil
  end
end
