# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing conditions" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let!(:condition_set) { planning_application.condition_set }
  let!(:standard_condition) { create(:condition, condition_set:) }
  let!(:other_condition) { create(:condition, :other, condition_set:) }
  let!(:current_review) { condition_set.current_review }

  context "when signed in as a reviewer" do
    before do
      current_review.complete!
      create(:recommendation, status: "assessment_complete", planning_application:)

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review conditions"

        within("#review-conditions") do
          expect(page).to have_content(standard_condition.title)
          expect(page).to have_content(standard_condition.text)
          expect(page).to have_content(standard_condition.reason)

          expect(page).to have_content(other_condition.text)
          expect(page).to have_content(other_condition.reason)

          choose "Agree"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        current_review.reload

        expect(current_review.action).to eq "accepted"
        expect(current_review.review_status).to eq "review_complete"
      end

      it "I can edit to accept the planning officer's decision" do
        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review conditions"

        within("#condition_#{other_condition.id}") do
          click_link "Edit to accept"
        end

        fill_in "Enter a reason for this condition", with: "This is different reason"
        click_button "Save condition"

        expect(page).to have_content("Condition was successfully saved")

        within("#review-conditions") do
          choose "Agree"

          click_button "Save and mark as complete"
        end

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        current_review.reload

        expect(current_review.action).to eq "accepted"
        expect(current_review.review_status).to eq "review_complete"

        other_condition.reload

        expect(other_condition.reason).to eq "This is different reason"
      end

      it "I can return to officer" do
        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review conditions"

        within("#review-conditions") do
          choose "Return with comments"

          fill_in "Add a comment", with: "I don't think you've assessed conditions correctly"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Awaiting changes")
        end

        current_review.reload

        expect(current_review.action).to eq "rejected"
        expect(current_review.comment).to eq "I don't think you've assessed conditions correctly"
        expect(current_review.status).to eq "to_be_reviewed"

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Add conditions",
          with: "To be reviewed"
        )

        click_link "Add conditions"

        expect(page).to have_content("I don't think you've assessed conditions correctly")

        within("#conditions-list li:last-of-type") do
          click_link "Edit"
        end
        fill_in "Enter a reason for this condition", with: "A better response"

        click_button "Add condition to list"
        click_button "Save and mark as complete"

        sign_out(assessor)
        sign_in(reviewer)

        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Updated")
        end

        click_button "Review conditions"

        within("#review-conditions") do
          expect(page).to have_content "A better response"
          choose "Agree"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        condition_set.reload
        new_review = condition_set.current_review

        expect(new_review.action).to eq "accepted"
        expect(new_review.review_status).to eq "review_complete"
        expect(new_review.status).to eq "complete"
      end
    end
  end
end
