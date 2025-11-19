# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review and submit pre-application task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }
  let(:case_record) { build(:case_record, user: assessor, local_authority:) }
  let(:planning_application) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
      :with_preapp_assessment,
      local_authority:,
      case_record:
    )
  end
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/review-and-submit-pre-application"
    )
  end

  def visit_task_list
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  def click_review_and_submit_task
    within ".bops-sidebar" do
      click_link "Review and submit pre-application"
    end
  end

  it "lets an assessor submit a recommendation and marks the task complete" do
    planning_application.case_record.update!(user: assessor)

    sign_in(assessor)
    visit_task_list

    expect(task.status).to eq("not_started")

    click_review_and_submit_task
    expect(page.current_url).to include("origin=review_and_submit_pre_application")
    expect(page).to have_selector("h1", text: "Pre-application report")

    click_button "Confirm and submit recommendation"

    expect(page).to have_selector("[role=alert] p", text: "Pre-application report submitted for review")
    expect(task.reload.status).to eq("completed")
  end

  it "keeps the user on the report view with origin when submission fails" do
    planning_application.case_record.update!(user: nil)

    sign_in(assessor)
    visit_task_list
    click_review_and_submit_task

    click_button "Confirm and submit recommendation"

    expect(page).to have_selector("[role=alert] p", text: "Pre-application report must be assigned to a case officer before it can be submitted for review")
    expect(page.current_url).to include("origin=review_and_submit_pre_application")
    expect(page).to have_selector(".bops-sidebar")
  end

  it "allows a reviewer to challenge then an assessor to resubmit and the reviewer to send" do
    planning_application.case_record.update!(user: assessor)

    sign_in(assessor)
    visit_task_list
    click_review_and_submit_task
    click_button "Confirm and submit recommendation"
    expect(task.reload.status).to eq("completed")

    sign_out(assessor)
    sign_in(reviewer)

    visit "/reports/planning_applications/#{planning_application.reference}?origin=review_and_submit_pre_application"

    within_fieldset "Do you agree with the advice?" do
      choose "No (return the case for assessment)"
      fill_in "Reviewer comment", with: "Needs more detail"
    end

    click_button "Confirm and submit pre-application report"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report has been sent back to the case officer for amendments")
    expect(task.reload.status).to eq("action_required")

    sign_out(reviewer)
    sign_in(assessor)

    visit_task_list
    click_review_and_submit_task
    fill_in "Assessor comment", with: "Added the missing detail"
    click_button "Confirm and submit recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report submitted for review")
    expect(task.reload.status).to eq("completed")

    sign_out(assessor)
    sign_in(reviewer)

    visit "/reports/planning_applications/#{planning_application.reference}?origin=review_and_submit_pre_application"

    within_fieldset "Do you agree with the advice?" do
      choose "Yes"
    end

    click_button "Confirm and submit pre-application report"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report has been sent to the applicant")
    expect(task.reload.status).to eq("completed")
  end
end
