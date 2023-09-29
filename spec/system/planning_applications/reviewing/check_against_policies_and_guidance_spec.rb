# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let!(:policy_area) { create(:policy_area, planning_application:, status: "complete") }

  context "when signed in as a reviewer" do
    before do
      sign_in(reviewer)
      visit planning_application_review_tasks_path(planning_application)
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Not started"
        )

        click_link "Review Assess against policies and guidance"

        expect(page).to have_content("Review Assess against policies and guidance")

        expect(page).to have_content(policy_area.policies)
        expect(page).to have_content(policy_area.assessment)

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyGuidance.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
      end

      it "I can edit to accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Not started"
        )

        click_link "Review Assess against policies and guidance"

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Edit to accept"
        end

        fill_in "Update officer comment", with: "This is the right comment"

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyGuidance.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.assessment).to eq "This is the right comment"
      end

      it "I can return to officer with comment" do
        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Not started"
        )

        click_link "Review Assess against policies and guidance"

        choose "Return to officer with comment"

        fill_in "Comment", with: "I don't think you've assessed Policy 1 correctly"

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Completed"
        )

        sign_out(reviewer)
        sign_in(assessor)

        visit planning_application_assessment_tasks_path(planning_application)

        expect(page).to have_list_item_for(
          "Assess against policies and guidance",
          with: "To be reviewed"
        )

        click_link "Assess against policies and guidance"

        expect(page).to have_content("I don't think you've assessed Policy 1 correctly")

        fill_in "What is your assessment of those policies?", with: "A better response"

        click_button "Save and mark as complete"

        sign_out(assessor)
        sign_in(reviewer)

        visit planning_application_review_tasks_path(planning_application)

        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Not started"
        )

        click_link "Review Assess against policies and guidance"

        expect(page).to have_content "A better response"

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review Assess against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyGuidance.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
      end
    end
  end
end
