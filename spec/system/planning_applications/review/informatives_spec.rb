# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing informatives" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority, name: "Anne Assessor") }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority, name: "Ray Reviewer") }

  let(:current_review) { planning_application.informative_set.current_review }

  shared_examples "an application type that supports informatives" do
    context "when signed in as a reviewer" do
      before do
        travel_to Time.zone.local(2024, 5, 20, 11)

        sign_in(assessor)
        visit "/planning_applications/#{planning_application.id}/assessment/tasks"

        click_link "Add informatives"
        expect(page).to have_selector("h1", text: "Add informatives")

        fill_in "Enter a title", with: "Section 106"
        fill_in "Enter details of the informative", with: "A Section 106 agreement will be required"

        click_button "Add informative"
        expect(page).to have_content("Informative was successfully added")

        click_button "Save and mark as complete"
        expect(page).to have_content("Informatives were successfully saved")

        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.id}/review/tasks"
      end

      context "when planning application is awaiting determination" do
        it "I can accept the planning officer's decision" do
          expect(page).to have_list_item_for("Review informatives", with: "Not started")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")

          within_fieldset("Do you accept the assessment against informatives?") do
            choose "Yes"
          end

          expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

          click_button "Save and mark as complete"

          expect(page).to have_content("Review of informatives updated successfully")
          expect(page).to have_list_item_for("Review informatives", with: "Completed")

          expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Informatives accepted by Ray Reviewer, 20 May 2024")
        end

        it "I can edit to accept the planning officer's decision" do
          expect(page).to have_list_item_for("Review informatives", with: "Not started")

          click_link "Review informatives"
          expect(page).to have_selector("h1", text: "Review informatives")

          click_link "Edit to accept"
          expect(page).to have_selector("h1", text: "Edit informative")

          fill_in "Enter a title", with: "Updated Section 106"
          fill_in "Enter details of the informative", with: "An updated Section 106 agreement will be required"

          click_button "Save informative"
          expect(page).to have_content("Informative was successfully saved")

          within_fieldset("Do you accept the assessment against informatives?") do
            choose "Yes"
          end

          expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

          click_button "Save and mark as complete"

          expect(page).to have_content("Review of informatives updated successfully")
          expect(page).to have_list_item_for("Review informatives", with: "Completed")

          expect(current_review.reload).to have_attributes(action: "edited_and_accepted", review_status: "review_complete")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Informatives edited and accepted by Ray Reviewer, 20 May 2024")
        end

        it "I can return to the planning officer with a comment" do
          expect(page).to have_list_item_for("Review informatives", with: "Not started")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")

          within_fieldset("Do you accept the assessment against informatives?") do
            choose "No"
            fill_in "Enter comment", with: "Please provide more details about the Section 106 agreement"
          end

          expect(current_review).to have_attributes(action: nil, review_status: "review_not_started", comment: nil)

          click_button "Save and mark as complete"

          expect(page).to have_content("Review of informatives updated successfully")
          expect(page).to have_list_item_for("Review informatives", with: "Awaiting changes")

          expect(current_review.reload).to have_attributes(action: "rejected", review_status: "review_complete", comment: "Please provide more details about the Section 106 agreement")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Informatives rejected by Ray Reviewer, 20 May 2024")

          travel_to Time.zone.local(2024, 5, 20, 12)
          sign_in(assessor)

          visit "/planning_applications/#{planning_application.id}/assessment/tasks"
          expect(page).to have_list_item_for("Add informatives", with: "To be reviewed")

          click_link "Add informatives"

          expect(page).to have_selector("h1", text: "Add informatives")
          expect(page).to have_content("Please provide more details about the Section 106 agreement")
          expect(page).to have_content("Sent on 20 May 2024 11:00 by Ray Reviewer")

          click_link "Edit"
          expect(page).to have_selector("h1", text: "Edit informative")

          fill_in "Enter a title", with: "Updated Section 106"
          fill_in "Enter details of the informative", with: "An updated Section 106 agreement will be required"

          click_button "Save informative"
          expect(page).to have_content("Informative was successfully saved")

          click_button "Save and mark as complete"
          expect(page).to have_content("Informatives were successfully saved")
          expect(page).to have_list_item_for("Add informatives", with: "Updated")

          travel_to Time.zone.local(2024, 5, 20, 13)
          sign_in(reviewer)

          visit "/planning_applications/#{planning_application.id}/review/tasks"
          expect(page).to have_list_item_for("Review informatives", with: "Updated")

          click_link "Review informatives"

          expect(page).to have_selector("h1", text: "Review informatives")

          within_fieldset("Do you accept the assessment against informatives?") do
            choose "Yes"
          end

          click_button "Save and mark as complete"
          expect(page).to have_content("Review of informatives updated successfully")
          expect(page).to have_list_item_for("Review informatives", with: "Completed")

          click_link "Review informatives"
          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Informatives accepted by Ray Reviewer, 20 May 2024")
        end
      end
    end
  end

  context "when the application is a full planning permission" do
    let!(:planning_application) do
      create(:planning_application, :planning_permission, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
    end

    it_behaves_like "an application type that supports informatives"
  end

  context "when the application is a LDC for a proposed development" do
    let!(:planning_application) do
      create(:planning_application, :ldc_proposed, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
    end

    it_behaves_like "an application type that supports informatives"
  end

  context "when the application is a LDC for an existing development" do
    let!(:planning_application) do
      create(:planning_application, :ldc_existing, :awaiting_determination, :with_recommendation, local_authority: default_local_authority)
    end

    it_behaves_like "an application type that supports informatives"
  end
end
