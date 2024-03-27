# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing heads of terms" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :with_heads_of_terms, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
  end

  context "when signed in as a reviewer" do
    before do
      create(:recommendation, status: "assessment_complete", planning_application:)
      create(:review, owner: planning_application.heads_of_term)

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

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")

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

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")

        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Completed"
        )

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "edited_and_accepted"
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
        expect(term.current_review.comment).to eq "I don't think you've assessed heads of terms correctly"
        expect(term.current_review.status).to eq "to_be_reviewed"

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.id}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Add heads of terms",
          with: "To be reviewed"
        )

        click_link "Add heads of terms"

        expect(page).to have_content("I don't think you've assessed heads of terms correctly")
      end
    end
  end
end
