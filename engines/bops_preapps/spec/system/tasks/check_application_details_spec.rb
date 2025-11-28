# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check application details task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-application-details") }

  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check application details"
    end
    choose "task-description-matches-documents-yes-field"
    choose "task-documents-consistent-yes-field"
    choose "task-proposal-details-match-documents-yes-field"
    choose "task-site-map-correct-yes-field"

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    expect(planning_application.reload.consistency_checklist.description_matches_documents).to eq "yes"
    expect(planning_application.reload.consistency_checklist.documents_consistent).to eq "yes"
    expect(planning_application.reload.consistency_checklist.proposal_details_match_documents).to eq "yes"
    expect(planning_application.reload.consistency_checklist.site_map_correct).to eq "yes"
  end
end
