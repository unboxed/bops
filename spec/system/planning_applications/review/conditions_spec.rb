# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing conditions" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let!(:condition_set) { create(:condition_set, planning_application:) }
  let!(:standard_condition) { create(:condition, condition_set:) }
  let!(:other_condition) { create(:condition, :other, condition_set:) }

  context "when signed in as a reviewer" do
    before do
      create(:recommendation, status: "assessment_complete", planning_application:)
      create(:review, owner: condition_set, status: "complete")
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

          choose "Accept"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        condition_set = planning_application.condition_set
        expect(condition_set.current_review.action).to eq "accepted"
        expect(condition_set.current_review.review_status).to eq "review_complete"
      end

      it "I can edit to accept the planning officer's decision" do
        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review conditions"

        within("#review-conditions") do
          click_link "Edit"
        end

        within("#condition_#{planning_application.condition_set.conditions.last.id}") do
          click_link "Edit"
        end

        fill_in "Enter a reason for this condition", with: "This is different reason"
        click_button "Add condition to list"

        expect(page).to have_content("Conditions successfully updated")

        within("#review-conditions") do
          choose "Accept"

          click_button "Save and mark as complete"
        end

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        condition_set = planning_application.condition_set
        expect(condition_set.current_review.action).to eq "accepted"
        expect(condition_set.conditions.last.reason).to eq "This is different reason"
        expect(condition_set.current_review.review_status).to eq "review_complete"
      end

      it "I can return to officer with comment" do
        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review conditions"

        within("#review-conditions") do
          choose "Return to officer"

          fill_in "Comment", with: "I don't think you've assessed conditions correctly"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Awaiting changes")
        end

        condition_set = planning_application.condition_set
        expect(condition_set.current_review.action).to eq "rejected"
        expect(condition_set.current_review.comment).to eq "I don't think you've assessed conditions correctly"
        expect(condition_set.current_review.status).to eq "to_be_reviewed"

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
          choose "Accept"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review conditions successfully updated")

        within("#review-conditions") do
          expect(page).to have_content("Review conditions")
          expect(page).to have_content("Completed")
        end

        condition_set = planning_application.condition_set
        expect(condition_set.current_review.action).to eq "accepted"
        expect(condition_set.current_review.review_status).to eq "review_complete"
        expect(condition_set.current_review.status).to eq "complete"
      end
    end
  end
end
