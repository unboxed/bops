# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing sign-off", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      name: "The name of assessor",
      local_authority: default_local_authority)
  end
  let(:user) { create(:user) }

  let!(:planning_application) do
    travel_to("2022-01-01") do
      create(
        :planning_application,
        :awaiting_determination,
        :ldc_proposed,
        local_authority: default_local_authority,
        decision: "granted",
        user:
      )
    end
  end

  let!(:consultation) do
    planning_application.consultation
  end

  before do
    sign_in reviewer
  end

  it "can be accepted" do
    create(:recommendation, :reviewed,
      planning_application:,
      assessor_comment: "First assessor comment",
      reviewer_comment: "First reviewer comment")

    create(:recommendation,
      planning_application:,
      assessor_comment: "New assessor comment",
      submitted: true)

    visit "/planning_applications/#{planning_application.reference}"

    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Review and sign-off"
    expect(list_item("Sign off recommendation")).to have_content("Not started")

    click_link "Sign off recommendation"

    expect(page).to have_content("Sign off recommendation")

    within ".recommendations" do
      expect(page).to have_content("First assessor comment")
      expect(page).to have_content("First reviewer comment")
      expect(page).to have_content("New assessor comment")
    end

    choose("Yes")
    click_button "Save and mark as complete"

    expect(page).to have_selector("h1", text: "Review and sign-off")
    expect(page).to have_content("Recommendation was successfully reviewed.")
    expect(page).to have_link("Sign off recommendation",
      href: edit_planning_application_review_recommendation_path(planning_application, planning_application.recommendation))

    expect(list_item("Sign off recommendation")).to have_content("Completed")

    click_on "Review and publish decision"

    click_button "Publish determination"

    planning_application.reload
    expect(planning_application.status).to eq("determined")
    expect(planning_application.recommendation.reviewer).to eq(reviewer)
    expect(planning_application.recommendation.reviewed_at).not_to be_nil
    expect(page).not_to have_content("Assigned to:")
    expect(page).not_to have_content("Process Application")
    perform_enqueued_jobs
    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 2)
    click_link("View decision notice")
    expect(page).to have_content("We certify that on the date of the application")
    expect(page).to have_content("were lawful")
    expect(page).to have_content("S.192")
    expect(page).to have_no_content("aggrieved")
  end

  it "can be rejected" do
    create(:recommendation,
      assessor:,
      planning_application:,
      assessor_comment: "New assessor comment",
      submitted: true)

    visit "/planning_applications/#{planning_application.reference}"
    click_link "Review and sign-off"

    expect(list_item("Sign off recommendation")).to have_content("Not started")

    click_link "Sign off recommendation"

    choose("No (return the case for assessment)")

    fill_in(
      "Explain to the officer why the case is being returned",
      with: "Reviewer private comment"
    )

    click_button "Save and mark as complete"

    expect(page).to have_content("Recommendation was successfully reviewed.")
    expect(list_item("Sign off recommendation")).to have_content("Completed")
    expect(page).to have_text("Sign off recommendation")
    expect(page).not_to have_link("Sign off recommendation",
      href: edit_planning_application_assessment_recommendations_path(planning_application))

    expect(page).to have_text "Application is now in assessment and assigned to The name of assessor"

    click_link "Back"

    expect(page).to have_content("Publish determination")
    expect(page).not_to have_link("Publish determination")

    planning_application.reload
    expect(planning_application.status).to eq("to_be_reviewed")
    expect(planning_application.recommendation.reviewer).to eq(reviewer)
    expect(planning_application.recommendation.reviewed_at).not_to be_nil
    expect(planning_application.recommendation.reviewer_comment).to eq("Reviewer private comment")

    perform_enqueued_jobs
    update_notification = ActionMailer::Base.deliveries.last

    expect(update_notification.to).to contain_exactly(user.email)

    expect(update_notification.subject).to eq(
      "BOPS case PlanX-22-00100-LDCP has a new update"
    )

    click_button "Audit log"
    click_link "View all audits"

    expect(page).to have_text("Recommendation challenged")
    expect(page).to have_text("Reviewer private comment")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "cannot be rejected without a review comment" do
    create(:recommendation,
      planning_application:,
      assessor_comment: "New assessor comment",
      submitted: true)

    visit "/planning_applications/#{planning_application.reference}"
    click_link "Review and sign-off"
    click_link "Sign off recommendation"

    choose("No")
    click_button "Save and mark as complete"

    find_all(".govuk-error-summary").each do |error|
      within(error) do
        expect(page).to have_content("Explain to the case officer why the recommendation has been challenged.")
      end
    end
  end

  it "can be accepted without a review comment" do
    create(:recommendation,
      planning_application:,
      assessor_comment: "New assessor comment",
      submitted: true)

    visit "/planning_applications/#{planning_application.reference}"
    click_link "Review and sign-off"
    click_link "Sign off recommendation"

    choose("Yes")
    click_button "Save and mark as complete"

    expect(page).to have_content("Recommendation was successfully reviewed.")
    expect(list_item("Sign off recommendation")).to have_content("Completed")

    click_link "Back"

    click_link "Publish determination"
    click_button "Publish determination"

    planning_application.reload
    expect(planning_application.status).to eq("determined")
  end

  it "can edit an existing review of an assessment" do
    recommendation = create(:recommendation, :reviewed, planning_application:,
      reviewer_comment: "Reviewer private comment")

    visit "/planning_applications/#{planning_application.reference}"
    click_link "Review and sign-off"
    click_link "Sign off recommendation"

    within ".recommendations" do
      expect(page).not_to have_content("Reviewer private comment")
    end

    expect(page).to have_field(
      "Explain to the officer why the case is being returned",
      with: "Reviewer private comment"
    )

    choose("No (return the case for assessment)")

    fill_in(
      "Explain to the officer why the case is being returned",
      with: "Edited reviewer private comment"
    )

    click_button "Save and mark as complete"

    expect(page).to have_content("Recommendation was successfully reviewed.")
    expect(list_item("Sign off recommendation")).to have_content("Completed")

    recommendation.reload
    expect(recommendation.reviewer_comment).to eq("Edited reviewer private comment")
  end

  context "when editing the public comment that appears on the decision notice" do
    it "as a reviewer I am able to edit", capybara: true do
      create(:recommendation,
        planning_application:,
        assessor_comment: "New assessor comment",
        submitted: true)

      visit "/planning_applications/#{planning_application.reference}"
      click_link "Review and sign-off"
      click_link "Sign off recommendation"

      expect(page).to have_content("Sign off recommendation")
      expect(page).to have_content("To grant")
      within(".govuk-warning-text") do
        expect(page).to have_content("This information will appear on the decision notice.")
      end
      expect(page).to have_content(planning_application.public_comment)

      click_link "Edit information on the decision notice"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/edit_public_comment")

      expect(page).to have_content("Edit the information appearing on the decision notice")
      expect(page).to have_content("The planning officer recommends that the application is granted")
      expect(page).to have_content("This information will appear on the decision notice.")

      # Attempt to save without any text input
      fill_in "This information will appear on the decision notice.", with: ""
      click_button "Save"

      within(".govuk-form-group--error") do
        expect(page).to have_content("Please state the reasons for your recommendation")
      end

      fill_in "This information will appear on the decision notice.", with: "This text will appear on the decision notice."
      click_button "Save"
      expect(page).to have_content("The information appearing on the decision notice was successfully updated.")
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/review/tasks")

      click_link "Sign off recommendation"

      expect(page).to have_content("This text will appear on the decision notice.")

      # Check audit log
      visit "/planning_applications/#{planning_application.reference}"
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
      visit "/planning_applications/#{planning_application.reference}/edit_public_comment"

      expect(page).to have_content("forbidden")

      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_content("forbidden")
    end
  end

  context "when the reviewer requests changes" do
    before do
      create(:recommendation, planning_application:)

      create(
        :permitted_development_right,
        planning_application:
      )
    end

    it "raises an error if the reviewer accepts the recommendation" do
      visit "/planning_applications/#{planning_application.reference}"
      click_link("Review and sign-off")
      click_link("Review permitted development rights")
      choose("Return to officer with comment")

      fill_in(
        "Explain to the assessor why this needs reviewing",
        with: "needs correction"
      )

      click_button("Save and mark as complete")
      click_link("Sign off recommendation")

      expect(page).to have_content(
        "You have suggested changes to be made by the officer"
      )

      choose("Yes")
      click_button("Save and mark as complete")

      expect(page).to have_content(
        "You have requested officer changes, resolve these before agreeing with the recommendation"
      )

      choose("No (return the case for assessment)")

      fill_in(
        "Explain to the officer why the case is being returned",
        with: "see permitted development rights"
      )

      click_button("Save and mark as complete")

      expect(page).to have_content("Recommendation was successfully reviewed.")
    end
  end

  context "when application type is prior approval" do
    let!(:planning_application) do
      travel_to("2022-01-01") do
        create(
          :planning_application,
          :awaiting_determination,
          :prior_approval,
          local_authority: default_local_authority
        )
      end
    end

    context "when consultation is still ongoing" do
      before do
        consultation.update(end_date: 10.days.from_now)
      end

      it "displays a warning message with the consultation end date" do
        visit "/planning_applications/#{planning_application.reference}/assessment/recommendations/new"

        within(".moj-banner__message") do
          expect(page).to have_content("The consultation is still ongoing. It will end on the #{consultation.end_date.to_fs(:day_month_year_slashes)}. Are you sure you still want to make the recommendation?")
        end
      end
    end

    context "when consultation hasn't begun" do
      before do
        consultation.update(end_date: nil)
      end

      it "does not display a warning message" do
        visit "/planning_applications/#{planning_application.reference}/assessment/recommendations/new"

        expect(page).not_to have_css(".moj-banner__message")
      end
    end
  end

  context "when application is going to committee" do
    it "I can mark it ready to go to committee" do
      create(:recommendation, planning_application:)

      create(:committee_decision, planning_application:, recommend: true)

      visit "/planning_applications/#{planning_application.reference}"

      click_link "Review and sign-off"
      expect(list_item("Sign off recommendation")).to have_content("Not started")

      click_link "Sign off recommendation"

      expect(page).to have_content "You haven't suggested changes to be made by the officer."

      choose "Yes (decision is ready to go to committee)"

      click_button "Save and mark as complete"

      expect(page).to have_content "Recommendation was successfully reviewed."

      expect(list_item("Sign off recommendation")).to have_content("Complete")
    end

    it "can be rejected" do
      create(:recommendation,
        assessor:,
        planning_application:,
        assessor_comment: "New assessor comment",
        submitted: true)

      create(:committee_decision, planning_application:, recommend: true)

      visit "/planning_applications/#{planning_application.reference}"
      click_link "Review and sign-off"

      expect(list_item("Sign off recommendation")).to have_content("Not started")

      click_link "Sign off recommendation"

      choose("No (return the case for assessment)")

      fill_in(
        "Explain to the officer why the case is being returned",
        with: "Reviewer private comment"
      )

      click_button "Save and mark as complete"

      expect(page).to have_content("Recommendation was successfully reviewed.")
      expect(list_item("Sign off recommendation")).to have_content("Completed")
      expect(page).to have_text("Sign off recommendation")
      expect(page).not_to have_link("Sign off recommendation",
        href: edit_planning_application_assessment_recommendations_path(planning_application))

      expect(page).to have_text "Application is now in assessment and assigned to The name of assessor"
    end
  end
end
