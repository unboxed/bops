# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Returning a recommendation for assessment", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }
  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:,
      decision: nil, public_comment: nil)
  end

  let(:make_draft_task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/make-draft-recommendation"
    )
  end

  let(:submit_task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/review-and-submit-recommendation"
    )
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)
  end

  it "resets the assessment task statuses and keeps the case 'to be reviewed'" do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"

    within :sidebar do
      click_link "Make draft recommendation"
    end
    within_fieldset("Does this planning application need to be decided by committee?") do
      choose "No"
    end
    within_fieldset("What is your recommendation?") do
      choose "Granted"
    end
    fill_in "State the reasons for your recommendation.", with: "Meets policy requirements."
    click_button "Save and mark as complete"

    within :sidebar do
      click_link "Review and submit recommendation"
    end
    click_button "Save and mark as complete"

    expect(planning_application.reload).to be_awaiting_determination
    expect(make_draft_task.reload).to be_completed
    expect(submit_task.reload).to be_completed

    switch_user(reviewer)
    visit "/planning_applications/#{planning_application.reference}/review/tasks"
    click_link "Sign off recommendation"
    choose "No (return the case for assessment)"
    fill_in "Explain to the officer why the case is being returned", with: "Please revise"
    click_button "Save and mark as complete"

    expect(planning_application.reload).to be_to_be_reviewed
    expect(make_draft_task.reload).to be_action_required
    expect(submit_task.reload).to be_action_required

    switch_user(assessor)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"

    within :sidebar do
      expect(page).to have_selector(:action_required_sidebar_task, "Make draft recommendation")
      expect(page).to have_selector(:action_required_sidebar_task, "Review and submit recommendation")
    end

    within :sidebar do
      click_link "Make draft recommendation"
    end
    within_fieldset("Does this planning application need to be decided by committee?") do
      choose "No"
    end
    within_fieldset("What is your recommendation?") do
      choose "Granted"
    end
    fill_in "State the reasons for your recommendation.", with: "Meets policy requirements."
    click_button "Save and mark as complete"

    expect(planning_application.reload).to be_to_be_reviewed

    within :sidebar do
      click_link "Review and submit recommendation"
    end
    click_button "Save and mark as complete"

    expect(planning_application.reload).to be_awaiting_determination
    expect(submit_task.reload).to be_completed
  end
end
