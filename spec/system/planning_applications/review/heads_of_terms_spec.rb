# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing heads of terms", type: :system, capybara: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :with_heads_of_terms, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
  end

  let!(:heads_of_terms) { planning_application.heads_of_term }
  let!(:current_review) { heads_of_terms.current_review }

  context "when signed in as a reviewer" do
    before do
      Current.user = reviewer
      travel_to Time.zone.local(2024, 1, 1, 11)

      current_review.complete!
      create(:recommendation, status: "assessment_complete", planning_application:)

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      let!(:term1) { create(:term, title: "Title 1", heads_of_term: heads_of_terms) }
      let!(:term2) { create(:term, title: "Title 2", heads_of_term: heads_of_terms) }

      it "I can accept the planning officer's decision" do
        within "#review-heads-of-terms" do
          expect(page).to have_content "Not started"
        end

        click_button "Review heads of terms"

        within "#review-heads-of-terms" do
          choose "Agree"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of heads of terms successfully updated")

        within "#review-heads-of-terms" do
          expect(page).to have_content "Completed"
        end

        expect(current_review.reload).to have_attributes(
          action: "accepted", review_status: "review_complete"
        )
      end

      it "I can return with comments" do
        within "#review-heads-of-terms" do
          expect(page).to have_content "Not started"
        end

        within "#review-heads-of-terms" do
          click_button "Review heads of terms"
          choose "Return with comments"

          fill_in "Add a comment", with: "I don't think you've assessed heads of terms correctly"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of heads of terms successfully updated")

        within "#review-heads-of-terms" do
          expect(page).to have_content "Awaiting changes"
        end

        expect(current_review.reload).to have_attributes(
          action: "rejected", status: "to_be_reviewed", comment: "I don't think you've assessed heads of terms correctly"
        )

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

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
