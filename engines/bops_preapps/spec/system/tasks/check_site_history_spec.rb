# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check site history", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path! "check-and-assess/check-application/check-site-history" }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check site history"
    end
    click_button "Add site history"

    click_button "Save changes"

    expect(task.reload).to be_in_progress
    expect(planning_application.reload.site_history_checked).not_to be true

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed
    expect(planning_application.reload.site_history_checked).to be true
  end
end
