# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing pre-commencement conditions" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority, pre_commencement_condition_set: condition_set)
  end

  let!(:condition_set) { create(:condition_set, pre_commencement: true) }
  let!(:standard_condition) { create(:condition, condition_set:, title: "foo", validation_requests: [validate]) }
  let!(:other_condition) { create(:condition, :other, condition_set:, title: "bar", validation_requests: [validate]) }

  def validate
    create(:pre_commencement_condition_validation_request, approved: true, planning_application:)
  end

  context "when signed in as a reviewer" do
    before do
      create(:recommendation, status: "assessment_complete", planning_application:)
      create(:review, owner: condition_set, status: "complete")
      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.id}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "Not started"
        )

        click_link "Review pre-commencement conditions"

        expect(page).to have_content("Review pre-commencement conditions")

        expect(page).to have_content(standard_condition.title)
        expect(page).to have_content(standard_condition.text)
        expect(page).to have_content(standard_condition.reason)

        expect(page).to have_content(other_condition.text)
        expect(page).to have_content(other_condition.reason)

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review conditions successfully updated")

        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "Completed"
        )

        condition_set = planning_application.pre_commencement_condition_set
        expect(condition_set.current_review.action).to eq "accepted"
        expect(condition_set.current_review.review_status).to eq "review_complete"
      end

      it "I can edit to accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "Not started"
        )

        click_link "Review pre-commencement conditions"

        choose "Edit to accept"

        within("#condition-set-conditions-attributes-1--destroy-conditional") do
          fill_in "Reason", with: "This is different reason"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Review conditions successfully updated")

        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "Completed"
        )

        condition_set = planning_application.pre_commencement_condition_set
        expect(condition_set.current_review.action).to eq "edited_and_accepted"
        expect(condition_set.conditions.last.reason).to eq "This is different reason"
        expect(condition_set.current_review.review_status).to eq "review_complete"
      end

      it "I can return to officer with comment" do
        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "Not started"
        )

        click_link "Review pre-commencement conditions"

        choose "Return to officer with comment"

        fill_in "Comment", with: "I don't think you've assessed conditions correctly"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review conditions successfully updated")

        expect(page).to have_list_item_for(
          "Review pre-commencement conditions",
          with: "To be reviewed"
        )

        condition_set = planning_application.pre_commencement_condition_set
        expect(condition_set.current_review.action).to eq "rejected"
        expect(condition_set.current_review.comment).to eq "I don't think you've assessed conditions correctly"
        expect(condition_set.current_review.status).to eq "to_be_reviewed"

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.id}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Add pre-commencement conditions",
          with: "Updated"
        )

        click_link "Add pre-commencement conditions"

        expect(page).to have_content("I don't think you've assessed conditions correctly")

        within "tbody tr:first-child" do
          click_link "Cancel"
        end
      end
    end
  end
end
