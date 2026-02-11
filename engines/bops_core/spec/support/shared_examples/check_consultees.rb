# frozen_string_literal: true

RSpec.shared_examples "check consultees task", :capybara do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-consultees") }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within :sidebar do
      click_link "Check consultees"
    end

    click_button "Save changes"

    expect(task.reload).to be_in_progress
    expect(planning_application.reload.consultation.current_review).to be_nil

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed

    review = planning_application.reload.consultation.current_review
    expect(review.review_type).to eq("consultees_checked")
    expect(review.status).to eq("complete")
  end
end
