# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
  let!(:reviewer) { create :user, :reviewer, local_authority: @default_local_authority }
  let!(:planning_application) do
    create :planning_application, :awaiting_determination, local_authority: @default_local_authority
  end
  let!(:recommendation) { create :recommendation, planning_application: planning_application }

  # TODO: have multiple previous recommendations, and check they are shown on page

  before do
    sign_in reviewer
    visit planning_application_path(planning_application)
  end

  it "can be accepted" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review Assessment"
    choose "Yes"
    click_button "Save"
    click_link "Publish"
    click_button "Determine application"

    # TODO: edit

    planning_application.reload
    expect(planning_application.status).to eq("determined")
    expect(planning_application.recommendations.last.reviewer).to eq(reviewer)
    expect(planning_application.recommendations.last.reviewed_at).not_to be_nil
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)
  end

  it "can be rejected" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review Assessment"
    choose "No"
    fill_in "Please provide comments on why you don't agree.", with: "Reviewer private comment"
    click_button "Save"
    expect(page).not_to have_link("Publish")

    planning_application.reload
    expect(planning_application.status).to eq("awaiting_correction")
    expect(planning_application.recommendations.last.reviewer).to eq(reviewer)
    expect(planning_application.recommendations.last.reviewed_at).not_to be_nil
    expect(planning_application.recommendations.last.reviewer_comment).to eq("Reviewer private comment")
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails)
  end

  it "raises error if no response given" do
    pending
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review Assessment"
    fill_in "Please provide comments on why you don't agree.", with: "Reviewer private comment"
    click_button "Save"
    expect(page).to have_content("Some error message")

    planning_application.reload
    expect(planning_application.status).to eq("awaiting_determination")
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails)
  end

  it "raises error if rejection doesn't include private comment"

  it "cannot be accessed by assessor"

  it "cannot be accessed when planning application is not in awaiting_determination"
end
