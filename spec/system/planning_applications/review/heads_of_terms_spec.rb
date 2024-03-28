# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing conditions" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  let!(:heads_of_terms) { create(:heads_of_term, planning_application:) }

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
          "Review heads of terms",
          with: "Not started"
        )

        click_link "Review heads of terms"

        expect(page).to have_content("Review heads of terms")

        # expect(page).to have_content(standard_condition.title)
        # expect(page).to have_content(standard_condition.text)
        # expect(page).to have_content(standard_condition.reason)
        #
        # expect(page).to have_content(other_condition.text)
        # expect(page).to have_content(other_condition.reason)

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review conditions successfully updated")

        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Completed"
        )

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "accepted"
        expect(term.current_review.review_status).to eq "review_complete"
      end

      it "I can edit to accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Not started"
        )

        click_link "Review heads of terms"

        choose "Edit to accept"

        within("#condition-set-conditions-attributes-1--destroy-conditional") do
          fill_in "Reason", with: "This is different reason"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")

        expect(page).to have_list_item_for(
          "Heads of terms",
          with: "Completed"
        )

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "accepted"
        expect(term.current_review.review_status).to eq "review_complete"
      end

      it "I can return to officer with comment" do
        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Not started"
        )

        click_link "Review heads of terms"

        choose "Return to officer with comment"

        fill_in "Comment", with: "I don't think you've assessed heads of terms correctly"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")

        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "To be reviewed"
        )

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "rejected"
        expect(term.current_review.comment).to eq "I don't think you've assessed conditions correctly"
        expect(term.current_review.status).to eq "to_be_reviewed"

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.id}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Heads of terms",
          with: "To be reviewed"
        )

        click_link "Heads of terms"

        expect(page).to have_content("I don't think you've assessed heads of terms correctly")

        click_link "Edit heads of terms"

        # need to create and approve new HoT

        click_button "Save and mark as complete"

        sign_out(assessor)
        sign_in(reviewer)

        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Updated"
        )

        click_link "Review heads of terms"

        expect(page).to have_content "A better response"

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")

        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Completed"
        )

        term = planning_application.heads_of_term
        expect(term.current_review.action).to eq "accepted"
        expect(term.current_review.review_status).to eq "review_complete"
        expect(term.current_review.status).to eq "complete"
      end
    end
  end
end
