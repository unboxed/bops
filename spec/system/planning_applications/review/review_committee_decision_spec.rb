# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review committee decision" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      local_authority: default_local_authority)
  end
  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :with_recommendation, local_authority: default_local_authority, user: assessor)
  end

  before do
    allow(Current).to receive(:user).and_return(reviewer)

    sign_in reviewer

    planning_application.committee_decision.update(recommend: true, reasons: ["The first reason"])
  end

  it "reviewer can agree with committee decision" do
    visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Not started"
    )

    click_link "Recommendation to committee"

    expect(page).to have_content "The case officer has marked this application as requiring decision by Committee for the following reasons:"
    expect(page).to have_content "The first reason"

    choose "Yes"

    click_button "Save and mark as complete"

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Completed"
    )
  end

  it "reviewer can disagree with decision" do
    visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Not started"
    )

    click_link "Recommendation to committee"

    expect(page).to have_content "The case officer has marked this application as requiring decision by Committee for the following reasons:"
    expect(page).to have_content "The first reason"

    choose "No (return the case for assessment)"

    fill_in "Explain why you do not agree with the recommendation", with: "It doesn't need to go to committee"

    click_button "Save and mark as complete"

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Completed"
    )

    click_link "Sign off recommendation"

    expect(page).to have_content "You have suggested changes to be made by the officer."

    choose "No (return the case for assessment)"

    fill_in "Explain to the officer why the case is being returned", with: "No committee"

    click_button "Save and mark as complete"

    click_link "Application"

    click_link "Check and assess"

    expect(page).to have_list_item_for(
      "Make draft recommendation",
      with: "To be reviewed"
    )

    click_link "Make draft recommendation"

    within_fieldset("Does this planning application need to be decided by committee?") do
      choose "No"
    end

    click_button "Update assessment"

    click_link "Review and submit recommendation"

    click_button "Submit recommendation"

    click_link "Review and sign-off"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Not started"
    )

    click_link "Recommendation to committee"

    expect(page).to have_content "The case officer has marked this application as not requiring decision by Committee."

    choose "Yes"

    click_button "Save and mark as complete"

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    expect(page).to have_list_item_for(
      "Recommendation to committee",
      with: "Completed"
    )
  end
end
