# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let!(:consideration1) { create(:consideration) }
  let!(:consideration2) { create(:consideration, policy_area: consideration1.policy_area, area: "Other") }

  context "when signed in as a reviewer" do
    before do
      consideration1.policy_area.update(planning_application:)
      sign_in(reviewer)
      visit planning_application_review_tasks_path(planning_application)
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        expect(page).to have_content("Review assessment against policies and guidance")

        expect(page).to have_content(consideration1.area)
        expect(page).to have_content(consideration1.policies)
        expect(page).to have_content(consideration1.guidance)
        expect(page).to have_content(consideration1.assessment)

        expect(page).to have_content(consideration2.area)
        expect(page).to have_content(consideration2.policies)
        expect(page).to have_content(consideration2.guidance)
        expect(page).to have_content(consideration2.assessment)

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyArea.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
      end

      it "I can edit to accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Edit to accept"
        end

        within("#review-policy-area-policy-area-considerations-attributes-0-areas-design-conditional") do
          fill_in "Enter your assessment", with: "It's all fine actually"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyArea.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.considerations.where(area: "Design").first.assessment).to eq "It's all fine actually"
      end

      it "I can return to officer with comment" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        choose "Return to officer with comment"

        fill_in "Comment", with: "I don't think you've assessed Policy 1 correctly"

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
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

        within("#policy-area-considerations-attributes-0-areas-design-conditional") do
          fill_in "Enter your assessment", with: "A better response"
        end

        click_button "Save and mark as complete"

        sign_out(assessor)
        sign_in(reviewer)

        visit planning_application_review_tasks_path(planning_application)

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        expect(page).to have_content "A better response"

        radio_buttons = find_all(".govuk-radios__item")
        within(radio_buttons[1]) do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_policy_area = ReviewPolicyArea.last
        expect(review_policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.policy_area.review_status).to eq "review_complete"
        expect(review_policy_area.status).to eq "complete"
        expect(review_policy_area.policy_area.status).to eq "complete"
      end
    end
  end
end
