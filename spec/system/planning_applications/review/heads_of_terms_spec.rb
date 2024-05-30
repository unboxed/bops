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
      visit "/planning_applications/#{planning_application.id}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      let!(:term1) { create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term) }
      let!(:term2) { create(:term, title: "Title 2", heads_of_term: planning_application.heads_of_term) }

      it "I can accept the planning officer's decision" do
        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Not started"
        )

        click_link "Review heads of terms"

        expect(page).to have_selector("h1", text: "Review heads of terms")

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

        # Edit first term
        within ".govuk-checkboxes .govuk-checkboxes__conditional", match: :first do
          fill_in "Enter a title", with: "This is a new title"
          fill_in "Enter detail", with: "This is a new detail"
        end

        # Unchecking second term should accept the term as it currently is
        uncheck "Title 2"

        click_button "Save and mark as complete"

        expect(page).to have_content("Review heads of terms successfully updated")
        expect(page).to have_list_item_for(
          "Review heads of terms",
          with: "Completed"
        )
        click_link "Review heads of terms"
        expect(page).to have_content("Edited and accepted by #{reviewer.name} on 1 January 2024 11:00")

        expect(term1.reload.title).to eq("This is a new title")
        expect(term2.reload.title).to eq("Title 2")

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
          with: "Awaiting changes"
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
