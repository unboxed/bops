# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }
  let(:user) { create(:user) }

  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      local_authority: default_local_authority,
      decision: "granted",
      created_at: DateTime.new(2022, 1, 1),
      user: user
    )
  end

  let!(:previous_recommendation) do
    create :recommendation, :reviewed,
           planning_application: planning_application,
           assessor_comment: "First assessor comment",
           reviewer_comment: "First reviewer comment"
  end
  let!(:recommendation) do
    create :recommendation,
           planning_application: planning_application,
           assessor_comment: "New assessor comment",
           submitted: true
  end

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
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 2)
    click_link("View decision notice")
    expect(page).to have_content("We certify that on the date of the application")
    expect(page).to have_content("were lawful")
    expect(page).to have_content("S.192")
    expect(page).to have_no_content("aggrieved")
  end

  it "can be rejected" do
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

    perform_enqueued_jobs
    update_notification = ActionMailer::Base.deliveries.last

    expect(update_notification.to).to contain_exactly(user.email)

    expect(update_notification.subject).to eq(
      "BoPS case RIPA-22-00100-LDCP has a new update"
    )

    click_button "Audit log"
    click_link "View all audits"

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
    recommendation = create :recommendation, :reviewed, planning_application: planning_application,
                                                        reviewer_comment: "Reviewer private comment"
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

  context "when editing the public comment that appears on the decision notice" do
    it "as a reviewer I am able to edit" do
      click_link "Review assessment"

      expect(page).to have_content("Review the recommendation")
      expect(page).to have_content("The planning officer recommends that the application is granted")
      expect(page).to have_content("This information will appear on the decision notice:")
      expect(page).to have_content(planning_application.public_comment)

      click_link "Edit information on the decision notice"
      expect(page).to have_current_path(edit_public_comment_planning_application_path(planning_application))

      expect(page).to have_content("Edit the information appearing on the decision notice")
      expect(page).to have_content("The planning officer recommends that the application is granted")
      expect(page).to have_content("This information will appear on the decision notice:")

      # Attempt to save without any text input
      fill_in "This information will appear on the decision notice:", with: ""
      click_button "Save"

      within(".govuk-form-group--error") do
        expect(page).to have_content("Please state the reasons why this application is, or is not lawful")
      end

      fill_in "This information will appear on the decision notice:", with: "This text will appear on the decision notice."
      click_button "Save"
      expect(page).to have_content("Planning application was successfully updated.")

      click_link "Review assessment"
      expect(page).to have_content("This text will appear on the decision notice.")

      # Check audit log
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Public comment updated")
        expect(page).to have_text("Changed from: All GDPO compliant Changed to: This text will appear on the decision notice.")
        expect(page).to have_text(reviewer.name)
        expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    it "as an assessor I am unable to edit" do
      sign_in assessor
      visit edit_public_comment_planning_application_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
