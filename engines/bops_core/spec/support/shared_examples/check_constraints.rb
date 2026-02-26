# frozen_string_literal: true

RSpec.shared_examples "check constraints task" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path! "check-and-validate/check-application-details/check-constraints" }
  let(:user) { create(:user, local_authority:) }

  before do
    Rails.application.load_seed
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "can complete and submit the form" do
    within :sidebar do
      click_link "Check constraints"
    end

    within(".identified-constraints-table") do
      expect(page).to have_text("Conservation area")
      expect(page).to have_text("Listed building outline")
    end

    click_button "Save and mark as complete"

    expect(page).to have_content "Constraints were successfully marked as reviewed"
    expect(task.reload).to be_completed

    expect(page).not_to have_button("Save and mark as complete")

    click_button "Edit"
    expect(page).to have_button("Save and mark as complete")
    expect(task.reload).to be_in_progress
  end

  it "can add and delete constraints" do
    within :sidebar do
      click_link "Check constraints"
    end

    toggle "Add constraints"

    within ".other-constraints-table tbody tr:first-child" do
      click_button "Add"
    end

    expect(page).to have_content "Successfully added constraint"
    expect(planning_application.planning_application_constraints.count).to eq 3

    within ".identified-constraints-table tbody tr:last-child" do
      click_button "Remove"
    end

    expect(page).to have_content "Successfully removed constraint"
    expect(planning_application.reload.planning_application_constraints.count).to eq 2
  end
end
