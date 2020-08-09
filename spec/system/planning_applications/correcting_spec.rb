# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application correction journey", type: :system do
    let(:assessor) { create :user, :assessor }
    let(:reviewer) { create :user, :reviewer }

    let!(:planning_application_corrected) do
      create :planning_application,
      :lawfulness_certificate,
      :awaiting_correction
    end

    let!(:assessor_decision) do
      create :decision,
             :granted,
             user: assessor,
             planning_application: planning_application_corrected
    end

    let!(:reviewer_decision) do
      create :decision,
             :granted,
             user: reviewer,
             planning_application: planning_application_corrected
    end

    # Required for submitting decision
    let!(:drawing) do
      create :drawing,
             :proposed_tags,
             :numbered,
             :with_plan,
             planning_application: planning_application_corrected
    end

    let(:policy_consideration_1) do
      create :policy_consideration
    end

    let!(:policy_evaluation) do
      create :policy_evaluation,
             planning_application: planning_application_corrected,
             policy_considerations: [policy_consideration_1]
    end

    context "Assessor responding to reviewer" do
      before do
        planning_application_corrected.reload.reviewer_decision.update!(private_comment: "please amend this information")
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

        click_button "Save"

        within(:assessment_step, "Reassess the proposal") do
          expect(page).to have_content("Completed")
        end

        click_link "Resubmit the recommendation"

        click_button "Submit to manager"

        expect(page).to have_text("Review the recommendation")
        expect(page).to have_text("Publish the recommendation")

        click_link "Home"

        expect(page).not_to have_text("Your manager has requested corrections")
        expect(page).to have_text("Corrections requested (0)")
        expect(page).not_to have_css(".corrections-banner")
      end
    end

    context "Reviewer first stage" do
      before do
        planning_application_corrected.awaiting_determination!
      end

      scenario "Reviewer can leave comment for assessor" do
        sign_in reviewer
        visit root_path

        click_link planning_application_corrected.reference

        click_link "Review the recommendation"

        choose "No"

        expect(page).to have_text("Please provide comments on why you don't agree.")

        fill_in "private_comment", with: "I don't agree"

        click_on "Save"

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

        choose "No"

        expect(page).to have_text("Please provide comments on why you don't agree.")

        click_on "Save"

        expect(page).to have_text("Please enter a reason in the box")
      end
    end

    context "Reviewer second stage" do
      before do
        planning_application_corrected.reload
        planning_application_corrected.awaiting_determination!
        planning_application_corrected.assessor_decision.update!(public_comment: "application should be granted ")
        planning_application_corrected.reviewer_decision.update!(private_comment: "please amend this information")
      end

      scenario "Reviewer can see corrections alert which disappears after determination" do
        sign_in reviewer
        visit root_path

        expect(page).to have_text("You have 1 application returned to you with corrections")

        click_link planning_application_corrected.reference

        # Verify the task list wording is correct
        expect(page).to have_text("Review the recommendation")
        expect(page).to have_text("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_text("please amend this information")
        expect(page).to have_text("You sent the following comment about the officer's recommendation")
        expect(page).to have_text("The planning officer has responded to your comment.")

        choose "Yes"

        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_content("Completed")
        end

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")

        click_button "Determine application"

        within(:assessment_step, "View the decision notice") do
          expect(page).to have_content("Completed")
        end

        click_link "Home"

        expect(page).not_to have_text("You have 1 application returned to you with corrections")
        expect(page).not_to have_css(".corrections-banner")
      end
    end
  end
