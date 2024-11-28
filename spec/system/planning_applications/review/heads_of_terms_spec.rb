# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing heads of terms", type: :system, capybara: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :with_heads_of_terms, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
  end

  context "when signed in as a reviewer" do
    before do
      Current.user = reviewer
      travel_to Time.zone.local(2024, 1, 1, 11)

      create(:recommendation, status: "assessment_complete", planning_application:)
      create(:review, owner: planning_application.heads_of_term)

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      let!(:term1) { create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term) }
      let!(:term2) { create(:term, title: "Title 2", heads_of_term: planning_application.heads_of_term) }

      it "I can accept the planning officer's decision" do
        within "#review-heads-of-terms" do
          expect(page).to have_content "Not started"
        end

        click_button "Review heads of terms"

        choose "Accept"

        within "#review-heads-of-terms" do
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review heads of terms successfully updated")

        within "#review-heads-of-terms" do
          expect(page).to have_content "Completed"
        end

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "accepted"
        expect(term.current_review.review_status).to eq "review_complete"
      end

      it "I can return to officer with comment" do
        within "#review-heads-of-terms" do
          expect(page).to have_content "Not started"
        end

        within "#review-heads-of-terms" do
          click_button "Review heads of terms"
          choose "Return to officer"

          fill_in "Comment", with: "I don't think you've assessed heads of terms correctly"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review heads of terms successfully updated")

        within "#review-heads-of-terms" do
          expect(page).to have_content "Awaiting changes"
        end

        term = HeadsOfTerm.last
        expect(term.current_review.action).to eq "rejected"
        expect(term.current_review.comment).to eq "I don't think you've assessed heads of terms correctly"
        expect(term.current_review.status).to eq "to_be_reviewed"

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
