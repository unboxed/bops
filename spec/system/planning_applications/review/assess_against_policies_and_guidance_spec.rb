# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let(:planning_application1) do
    travel_to(10.days.ago) { create(:planning_application) }
  end

  let!(:local_policy_area1) {
    travel_to(Time.zone.local(2024, 4, 17, 11, 30)) { create(:local_policy_area) }
  }
  let!(:local_policy_area2) {
    travel_to(Time.zone.local(2024, 4, 17, 11, 30)) { create(:local_policy_area, local_policy: local_policy_area1.local_policy, area: "Other") }
  }

  context "when signed in as a reviewer" do
    before do
      create(:recommendation, planning_application:, status: "assessment_complete")
      local_policy_area1.local_policy.reload.update!(planning_application:)
      travel_to(Time.zone.local(2024, 4, 17, 11, 30)) { create(:review, owner: local_policy_area1.local_policy) }

      sign_in(reviewer)
      Current.user = reviewer
      visit "/planning_applications/#{planning_application.id}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
        expect(page).to have_selector("p", text: "What you need to do")
        expect(page).to have_selector("li", text: "check the assessment")
        expect(page).to have_selector("li", text: "make minor changes by updating the text on this page")
        expect(page).to have_selector("li", text: "select 'yes' to accept the assessment")
        expect(page).to have_selector("li", text: "if you want to return to the case officer with comments, select 'no'")
        expect(page).to have_selector("legend", text: "Do you accept the assessment against policies and guidance?")

        expect(page).to have_content(local_policy_area1.area)
        expect(page).to have_content(local_policy_area1.policies)
        expect(page).to have_content(local_policy_area1.guidance)
        expect(page).to have_content(local_policy_area1.assessment)

        expect(page).to have_content(local_policy_area2.area)
        expect(page).to have_content(local_policy_area2.policies)
        expect(page).to have_content(local_policy_area2.guidance)
        expect(page).to have_content(local_policy_area2.assessment)

        choose "Yes"

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_local_policy = Review.where(owner_type: "LocalPolicy").last
        expect(review_local_policy.review_status).to eq "review_complete"
        expect(review_local_policy.status).to eq "complete"
      end

      it "I can edit the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        expect(page).to have_selector("h2", text: "Case officer's assessment")
        within("#local_policy_area_#{local_policy_area1.id}") do
          expect(page).to have_selector("h2", text: "1: Design")
          expect(page).to have_selector("p strong", text: "Relevant policies")
          expect(page).to have_selector("p", text: "Policy 1, Policy 2")
          expect(page).to have_selector("p strong", text: "Guidance")
          expect(page).to have_selector("p", text: "Local policy 1")
          expect(page).to have_selector("p strong", text: "Assessment")
          expect(page).to have_selector("p", text: "This is fine")
          expect(page).to have_selector("p strong", text: "Conclusion")
          expect(page).to have_selector("p", text: "A conclusion")

          click_link "Edit"
        end

        fill_in "Enter your assessment", with: "This is fine."
        fill_in "Enter a conclusion", with: "This is my conclusion."
        click_button "Update consideration"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")
        within("#local_policy_area_#{local_policy_area1.id}") do
          expect(page).to have_selector("p", text: "This is fine.")
          expect(page).to have_selector("p", text: "This is my conclusion.")
        end

        choose "Yes"
        click_button "Save and mark as complete"

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_local_policy = Review.where(owner_type: "LocalPolicy").last
        expect(review_local_policy.review_status).to eq "review_complete"
        expect(review_local_policy.status).to eq "complete"
        expect(review_local_policy.owner.local_policy_areas.where(area: "Design").first.assessment).to eq "This is fine."
      end

      it "I can return to officer with comment" do
        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        choose "No (return to officer with comment)"

        fill_in "Enter comment", with: "I don't think you've assessed Policy 1 correctly"

        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        sign_out(reviewer)
        sign_in(assessor)
        Current.user = assessor

        visit "/planning_applications/#{planning_application.id}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Assess against policies and guidance",
          with: "To be reviewed"
        )

        click_link "Assess against policies and guidance"

        expect(page).to have_content("I don't think you've assessed Policy 1 correctly")

        design_table_row = page.all("tr")[1]
        within(design_table_row) do
          click_link "Edit"
        end

        fill_in "Enter your assessment", with: "A better response"

        click_button "Update consideration"

        sign_out(assessor)
        sign_in(reviewer)
        Current.user = reviewer

        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Not started"
        )

        click_link "Review assessment against policies and guidance"

        find("span", text: "Previous comments").click
        within(".govuk-details__text") do
          expect(page).to have_selector("p", text: reviewer.name)
          expect(page).to have_selector("p", text: "17 April 2024 11:30")
          expect(page).to have_selector("p", text: "Reviewer comment: I don't think you've assessed Policy 1 correctly")
        end

        within("#local_policy_area_#{local_policy_area1.id}") do
          expect(page).to have_selector("p", text: "A better response")
        end

        choose "Yes"
        click_button "Save and mark as complete"

        expect(page).to have_content("Check against policy and guidance response was successfully updated")

        expect(page).to have_list_item_for(
          "Review assessment against policies and guidance",
          with: "Completed"
        )

        review_local_policy = Review.where(owner_type: "LocalPolicy").last
        expect(review_local_policy.review_status).to eq "review_complete"
        expect(review_local_policy.status).to eq "complete"
      end
    end
  end
end
