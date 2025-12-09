# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path! "check-and-assess/assessment-summaries/site-description" }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Site description"
    end

    fill_in "Description of the site", with: "Words words words"

    click_button "Save changes"

    expect(page).to have_content "Site description was successfully updated"
    expect(task.reload).to be_in_progress

    expect(planning_application.reload.assessment_details.where(category: :site_description).last.entry).to eq("Words words words")

    click_button "Save and mark as complete"

    expect(page).to have_content "Site description was successfully updated"
    expect(task.reload).to be_completed
  end
end
