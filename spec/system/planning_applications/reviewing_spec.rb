# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
  let!(:reviewer) { create :user, :reviewer, local_authority: @default_local_authority }
  let!(:planning_application) do
    create :planning_application, :awaiting_determination, local_authority: @default_local_authority, decision: "granted"
  end
  let!(:previous_recommendation) do
    create :recommendation, :reviewed,
           planning_application: planning_application,
           assessor_comment: "First assessor comment",
           reviewer_comment: "First reviewer comment"
  end
  let!(:recommendation) { create :recommendation, planning_application: planning_application, assessor_comment: "New assessor comment" }

  before do
    sign_in reviewer
    visit planning_application_path(planning_application)
  end

  it "can be accepted" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review assessment"

    within ".recommendations" do
      expect(page).to have_content("First assessor comment")
      expect(page).to have_content("First reviewer comment")
      expect(page).to have_content("New assessor comment")
    end

    choose "Yes"
    fill_in "Review comment", with: "Reviewer private comment"
    click_button "Save"
    click_link "Publish determination"
    click_button "Determine application"

    planning_application.reload
    expect(planning_application.status).to eq("determined")
    expect(planning_application.recommendations.last.reviewer).to eq(reviewer)
    expect(planning_application.recommendations.last.reviewed_at).not_to be_nil
    expect(planning_application.recommendations.last.reviewer_comment).to eq("Reviewer private comment")
    expect(page).not_to have_content("Assigned to:")
    expect(page).not_to have_content("Process Application")
    expect(page).not_to have_content("Review Assessment")
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)
    click_link("View decision notice")
    expect(page).to have_content("IT IS HEREBY CERTIFIED")
  end

  it "can be rejected" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review assessment"
    choose "No"
    fill_in "Review comment", with: "Reviewer private comment"
    click_button "Save"
    expect(page).not_to have_link("Publish determination")

    planning_application.reload
    expect(planning_application.status).to eq("awaiting_correction")
    expect(planning_application.recommendations.last.reviewer).to eq(reviewer)
    expect(planning_application.recommendations.last.reviewed_at).not_to be_nil
    expect(planning_application.recommendations.last.reviewer_comment).to eq("Reviewer private comment")
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Recommendation challenged")
    expect(page).to have_text("Reviewer private comment")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "cannot be rejected without a review comment" do
    click_link "Review assessment"
    choose "No"
    click_button "Save"
    expect(page).to have_content("Please include a comment for the case officer to indicate why the recommendation has been challenged.")
  end

  it "can be accepted without a review comment" do
    click_link "Review assessment"
    choose "Yes"
    click_button "Save"
    click_link "Publish determination"
    click_button "Determine application"

    planning_application.reload
    expect(planning_application.status).to eq("determined")
  end

  it "can edit an existing review of an assessment" do
    recommendation = create :recommendation, :reviewed, planning_application: planning_application, reviewer_comment: "Reviewer private comment"
    click_link "Review assessment"

    within ".recommendations" do
      expect(page).to have_content("First assessor comment")
      expect(page).to have_content("First reviewer comment")
      expect(page).to have_content("New assessor comment")
      expect(page).not_to have_content("Reviewer private comment")
    end

    expect(page).to have_field("Review comment", with: "Reviewer private comment")

    choose "No"
    fill_in "Review comment", with: "Edited reviewer private comment"
    click_button "Save"

    recommendation.reload
    expect(recommendation.reviewer_comment).to eq("Edited reviewer private comment")
  end
end
