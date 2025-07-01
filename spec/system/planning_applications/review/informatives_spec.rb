# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing informatives", js: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority, name: "Anne Assessor") }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority, name: "Ray Reviewer") }

  let(:current_review) { planning_application.informative_set.current_review }
  let(:reference) { planning_application.reference }

  shared_examples "an application type that supports informatives" do
    context "when signed in as a reviewer" do
      before do
        travel_to Time.zone.local(2024, 5, 20, 11)

        sign_in(assessor)
        visit "/planning_applications/#{reference}/assessment/tasks"

        click_link "Add informatives"
        expect(page).to have_selector("h1", text: "Add informatives")

        fill_in "Enter a title", with: "Section 106"
        fill_in "Enter details of the informative", with: "A Section 106 agreement will be required"

        click_button "Add informative"
        expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

        # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
        with_retry do
          expect(page).to have_content("Informative was successfully added")
        end

        toggle "Add new informative"
        expect(page).to have_selector("legend", text: "Add a new informative", visible: true)

        fill_in "Enter a title", with: "Section 206"
        fill_in "Enter details of the informative", with: "A Section 206 agreement will be required"

        click_button "Add informative"
        expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")
        expect(page).to have_content("Informative was successfully added")

        click_button "Save and mark as complete"
        expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
        expect(page).to have_content("Informatives were successfully saved")

        sign_in(reviewer)
        visit "/planning_applications/#{reference}/review/tasks"
      end

      context "when planning application is awaiting determination" do
        it "shows validation errors" do
          click_button "Review informatives"

          within("#review-informatives") do
            click_button("Save and mark as complete")
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/informatives")
          expect(page).to have_selector("[role=alert] p", text: "There was an error submitting your review")

          within("#review-informatives") do
            within(".bops-task-accordion__section-header") do
              expect(find("button")[:"aria-expanded"]).to eq("true")
            end

            within(".bops-task-accordion__section-footer") do
              expect(page).to have_selector("p.govuk-error-message", text: "Select an option")
            end

            within(".bops-task-accordion__section-footer") do
              choose "Return with comments"
              click_button("Save and mark as complete")
            end
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/informatives")
          expect(page).to have_selector("[role=alert] p", text: "There was an error submitting your review")

          within("#review-informatives") do
            within(".bops-task-accordion__section-header") do
              expect(find("button")[:"aria-expanded"]).to eq("true")
            end

            within(".bops-task-accordion__section-footer") do
              expect(page).to have_selector("p.govuk-error-message", text: "Explain to the case officer why")
            end
          end
        end

        it "I can accept the planning officer's decision" do
          click_button "Review informatives"

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Not started")

            within("li:nth-child(1)") do
              expect(page).to have_selector("span", text: "Informative 1")
              expect(page).to have_selector("h2", text: "Section 106")
              expect(page).to have_link(
                "Edit",
                href: %r{/planning_applications/#{reference}/review/informatives/items/\d+/edit}
              )
              expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: false)

              click_button("Show more")
              expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: true)

              click_button("Show less")
              expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: false)
            end

            within("li:nth-child(2)") do
              expect(page).to have_selector("span", text: "Informative 2")
              expect(page).to have_selector("h2", text: "Section 206")
              expect(page).to have_link(
                "Edit",
                href: %r{/planning_applications/#{reference}/review/informatives/items/\d+/edit}
              )
              expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: false)

              click_button("Show more")
              expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: true)

              click_button("Show less")
              expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: false)
            end

            expect(page).to have_link(
              "Rearrange informatives",
              href: "/planning_applications/#{reference}/review/informatives/edit"
            )

            within(".bops-task-accordion__section-footer") do
              choose "Agree"

              expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")
              click_button "Save and mark as complete"
            end
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks?next=true")

          # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
          with_retry do
            expect(page).to have_content("Review of informatives updated successfully")
          end

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")
        end

        it "I can edit the planning officer's decision" do
          click_button "Review informatives"

          within("#review-informatives") do
            within("li:first-child") do
              click_link "Edit to accept"
            end
          end

          expect(page).to have_selector("h1", text: "Edit informative")

          fill_in "Enter a title", with: "Updated Section 106"
          fill_in "Enter details of the informative", with: "An updated Section 106 agreement will be required"

          click_button "Save informative"

          expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks")
          expect(page).to have_content("Informative was successfully saved")

          expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

          within("#review-informatives") do
            choose "Agree"
            click_button "Save and mark as complete"
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks?next=true")

          # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
          with_retry do
            expect(page).to have_content("Review of informatives updated successfully")
          end

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")

          click_button("Review informatives")
          click_link("Rearrange informatives")

          expect(page).to have_content("Assessment accepted by Ray Reviewer, 20 May 2024")
        end

        it "I can return to the planning officer with a comment" do
          click_button "Review informatives"

          expect(current_review).to have_attributes(action: nil, review_status: "review_not_started", comment: nil)

          within("#review-informatives") do
            choose "Return with comments"
            fill_in "Add a comment", with: "Please provide more details about the Section 106 agreement"

            click_button "Save and mark as complete"
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks?next=true")

          # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
          with_retry do
            expect(page).to have_content("Review of informatives updated successfully")
          end

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Awaiting changes")
          end

          expect(current_review.reload).to have_attributes(action: "rejected", review_status: "review_complete", comment: "Please provide more details about the Section 106 agreement")

          click_button "Review informatives"
          click_link("Rearrange informatives")

          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Assessment rejected by Ray Reviewer, 20 May 2024")

          travel_to Time.zone.local(2024, 5, 20, 12)
          sign_in(assessor)

          visit "/planning_applications/#{reference}/assessment/tasks"
          expect(page).to have_list_item_for("Add informatives", with: "To be reviewed")

          click_link "Add informatives"

          expect(page).to have_selector("h1", text: "Add informatives")
          expect(page).to have_content("Please provide more details about the Section 106 agreement")
          expect(page).to have_content("Sent on 20 May 2024 11:00 by Ray Reviewer")

          within("ol.sortable-list li:first-child") do
            click_link "Edit"
          end

          expect(page).to have_selector("h1", text: "Edit informative")

          fill_in "Enter a title", with: "Updated Section 106"
          fill_in "Enter details of the informative", with: "An updated Section 106 agreement will be required"

          click_button "Save informative"
          expect(page).to have_content("Informative was successfully saved")

          click_button "Save and mark as complete"
          expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
          expect(page).to have_content("Informatives were successfully saved")
          expect(page).to have_list_item_for("Add informatives", with: "Updated")

          travel_to Time.zone.local(2024, 5, 20, 13)
          sign_in(reviewer)

          visit "/planning_applications/#{reference}/review/tasks"

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Updated")
          end

          click_button("Review informatives")

          within("#review-informatives") do
            choose "Agree"

            click_button "Save and mark as complete"
          end

          expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks?next=true")

          # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
          with_retry do
            expect(page).to have_content("Review of informatives updated successfully")
          end

          within("#review-informatives") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          click_button("Review informatives")
          click_link("Rearrange informatives")

          expect(page).to have_content("Assessment accepted by Ray Reviewer, 20 May 2024")
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
