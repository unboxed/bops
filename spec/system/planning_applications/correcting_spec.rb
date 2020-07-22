# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application correction journey", type: :system do
    let(:assessor) { create :user, :assessor }
    let(:reviewer) { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, :granted, user: assessor) }
    let(:reviewer_decision) { create(:decision, :granted, user: reviewer) }

    let!(:planning_application_corrected) do
      create :planning_application,
             :lawfulness_certificate,
             :awaiting_determination,
             assessor_decision: assessor_decision,
             reviewer_decision: reviewer_decision
    end

    let(:policy_consideration_1) do
      create :policy_consideration,
             policy_question: "The property is",
             applicant_answer: "a semi detached house"
    end

    let(:policy_consideration_2) do
      create :policy_consideration,
             policy_question: "The project will ___ the internal floor area of the building",
             applicant_answer: "not alter"
    end

    let!(:policy_evaluation) do
      create :policy_evaluation,
             planning_application: planning_application_corrected,
             policy_considerations: [policy_consideration_1, policy_consideration_2]
    end

    context "Assessor responding to reviewer" do
      before do
        planning_application_corrected.assessor_decision.update!(comment_met: "application should be granted ")
        planning_application_corrected.reviewer_decision.update!(correction: "please amend this information")
      end

      scenario "Assessment can be corrected and resubmitted" do
        sign_in assessor
        visit root_path

        expect(page).to have_text("Your manager has requested corrections on 1 application")
        expect(page).to have_css(".corrections-banner")

        click_link("Corrections requested (1)")
        click_link planning_application_corrected.reference

        # Verify the task list wording is correct
        expect(page).to have_text("Reassess the proposal")
        expect(page).to have_text("Resubmit the recommendation")

        click_link "Reassess the proposal"

        expect(page).to have_text("please amend this information")

        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end

        choose "Yes"

        expect(page).to have_text("application should be granted")

        # The next step appends the extra comment to the existing one instead of overwriting
        find_field("comment_met").native.send_keys(". This is the second assessor comment")

        click_button "Save"
        expect(page).to have_css(".app-task-list__task-completed")

        click_link "Resubmit the recommendation"

        click_button "Submit to manager"

        expect(page).to have_css(".app-task-list__task-completed")

        click_link "Home"

        expect(page).not_to have_text("Your manager has requested corrections")
        expect(page).to have_text("Corrections requested (0)")
        expect(page).not_to have_css(".corrections-banner")
      end
    end

    context "Reviewer first stage" do
      before do
        planning_application_corrected.assessor_decision.update!(comment_met: "application should be granted ")
      end

      scenario "Reviewer can leave comment for assessor" do
        sign_in reviewer
        visit root_path

        click_link planning_application_corrected.reference

        click_link "Review the recommendation"

        expect(page).to have_text("application should be granted ")

        choose "No"

        expect(page).to have_text("Please provide comments on why you don't agree.")

        fill_in "correction", with: "I don't agree"

        click_on "commit"

        expect(page).to have_css(".app-task-list__task-completed")

        click_link "Home"
        expect(page).not_to have_css("corrections-banner")
        click_link "Corrections requested"
        expect(page).to have_text(planning_application_corrected.reference)
      end

      scenario "Reviewer is unable to submit correction without reason" do
        sign_in reviewer
        visit root_path

        click_link planning_application_corrected.reference

        click_link "Review the recommendation"

        expect(page).to have_text("application should be granted ")

        choose "No"

        expect(page).to have_text("Please provide comments on why you don't agree.")

        click_on "commit"

        expect(page).to have_text("Please enter a reason in the box")
      end
    end

    context "Reviewer second stage" do
      before do
        planning_application_corrected.assessor_decision.update!(comment_met: "application should be granted ")
        planning_application_corrected.reviewer_decision.update!(correction: "please amend this information")
        planning_application_corrected.assessor_decision.update!(comment_met: "application should be granted. This is the second assessor comment")
      end

      scenario "Reviewer can see corrections alert which disappears after determination" do
        sign_in reviewer
        visit root_path

        expect(page).to have_text("You have 1 application returned to you with corrections")

        click_link planning_application_corrected.reference

        # Verify the task list wording is correct
        expect(page).to have_text("Review the corrections")
        expect(page).to have_text("Publish the recommendation")

        click_link "Review the corrections"

        expect(page).to have_text("application should be granted. This is the second assessor comment")
        expect(page).to have_text("please amend this information")
        expect(page).to have_text("You sent the following comment about the officer's recommendation")
        expect(page).to have_text("The planning officer has responded to your comment")

        choose "Yes"

        click_button "Save"

        expect(page).to have_css(".app-task-list__task-completed")

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        expect(page).not_to have_text("You have 1 application returned to you with corrections")
        expect(page).not_to have_css(".corrections-banner")
      end
    end
  end
