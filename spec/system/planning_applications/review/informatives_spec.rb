# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing informatives", js: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority, name: "Anne Assessor") }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority, name: "Ray Reviewer") }

  let(:current_review) { planning_application.informative_set.current_review }

  shared_examples "an application type that supports informatives" do
    context "when signed in as a reviewer" do
      before do
        travel_to Time.zone.local(2024, 5, 20, 11)

        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

        click_link "Add informatives"
        expect(page).to have_selector("h1", text: "Add informatives")

        fill_in "Enter a title", with: "Section 106"
        fill_in "Enter details of the informative", with: "A Section 106 agreement will be required"

        click_button "Add informative"
        expect(page).to have_content("Informative was successfully added")

        toggle "Add new informative"
        fill_in "Enter a title", with: "Section 206"
        fill_in "Enter details of the informative", with: "A Section 206 agreement will be required"
        click_button "Add informative"

        click_button "Save and mark as complete"
        expect(page).to have_content("Informatives were successfully saved")

        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}/review/tasks"
      end

      context "when planning application is awaiting determination" do
        it "shows validation errors" do
          click_button "Review informatives"
          within("#informatives_footer") do
            click_button("Save and mark as complete")
          end
          expect(page).to have_selector("[role=alert] li", text: "Select an option")

          within("#informatives_section") do
            within(".bops-task-accordion__section-header") do
              expect(find("button")[:"aria-expanded"]).to eq("true")
            end
            within("#informatives_footer") do
              expect(page).to have_selector("p.govuk-error-message", text: "Select an option")
            end

            within("#informatives_footer") do
              choose("Return to officer")
              click_button("Save and mark as complete")
            end
          end

          expect(page).to have_selector("[role=alert] li", text: "Explain to the case officer why")

          within("#informatives_section") do
            within(".bops-task-accordion__section-header") do
              expect(find("button")[:"aria-expanded"]).to eq("true")
            end
            within("#informatives_footer") do
              expect(page).to have_selector("p.govuk-error-message", text: "Explain to the case officer why")
            end
          end
        end

        it "I can accept the planning officer's decision" do
          click_button "Review informatives"

          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Not started")
            informative1 = Informative.first
            informative2 = Informative.second

            within("#informatives_block") do
              within("#informative_#{informative1.id}") do
                expect(page).to have_selector("span", text: "Informative 1")
                expect(page).to have_selector("h2", text: "Section 106")
                expect(page).to have_link(
                  "Edit",
                  href: "/planning_applications/#{planning_application.reference}/review/informatives/items/#{informative1.id}/edit"
                )
                expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: false)

                click_button("Show more")
                expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: true)

                click_button("Show less")
                expect(page).to have_selector("p", text: "A Section 106 agreement will be required", visible: false)
              end
              within("#informative_#{informative2.id}") do
                expect(page).to have_selector("span", text: "Informative 2")
                expect(page).to have_selector("h2", text: "Section 206")
                expect(page).to have_link(
                  "Edit",
                  href: "/planning_applications/#{planning_application.reference}/review/informatives/items/#{informative2.id}/edit"
                )
                expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: false)

                click_button("Show more")
                expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: true)

                click_button("Show less")
                expect(page).to have_selector("p", text: "A Section 206 agreement will be required", visible: false)
              end

              expect(page).to have_link(
                "Edit list position",
                href: "/planning_applications/#{planning_application.reference}/review/informatives/edit"
              )
            end
          end

          within("#informatives_footer") do
            within_fieldset("Do you accept the assessment against informatives?") do
              choose "Agree"
            end

            expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Review of informatives updated successfully")
          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")
        end

        it "I can edit the planning officer's decision" do
          click_button "Review informatives"

          within("#informatives_block") do
            within("#informative_#{Informative.first.id}") do
              click_link "Edit"
            end
          end
          expect(page).to have_selector("h1", text: "Edit informative")

          fill_in "Enter a title", with: "Updated Section 106"
          fill_in "Enter details of the informative", with: "An updated Section 106 agreement will be required"

          click_button "Save informative"
          expect(page).to have_content("Informative was successfully saved")

          click_button "Review informatives"
          within("#informatives_footer") do
            within_fieldset("Do you accept the assessment against informatives?") do
              choose "Agree"
            end
            expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Review of informatives updated successfully")
          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")
          click_button("Review informatives")
          click_link("Edit list position")
          expect(page).to have_content("Informatives accepted by Ray Reviewer, 20 May 2024")
        end

        it "I can return to the planning officer with a comment" do
          click_button "Review informatives"

          within("#informatives_footer") do
            within_fieldset("Do you accept the assessment against informatives?") do
              choose "Return to officer"
              fill_in "Add a comment", with: "Please provide more details about the Section 106 agreement"
            end

            expect(current_review).to have_attributes(action: nil, review_status: "review_not_started", comment: nil)
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Review of informatives updated successfully")
          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Awaiting changes")
          end

          expect(current_review.reload).to have_attributes(action: "rejected", review_status: "review_complete", comment: "Please provide more details about the Section 106 agreement")

          click_button "Review informatives"
          click_link("Edit list position")

          expect(page).to have_selector("h1", text: "Review informatives")
          expect(page).to have_content("Informatives rejected by Ray Reviewer, 20 May 2024")

          travel_to Time.zone.local(2024, 5, 20, 12)
          sign_in(assessor)

          visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
          expect(page).to have_list_item_for("Add informatives", with: "To be reviewed")

          click_link "Add informatives"

          expect(page).to have_selector("h1", text: "Add informatives")
          expect(page).to have_content("Please provide more details about the Section 106 agreement")
          expect(page).to have_content("Sent on 20 May 2024 11:00 by Ray Reviewer")

          within("#informative_#{Informative.first.id}") do
            click_link "Edit"
          end

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

          visit "/planning_applications/#{planning_application.reference}/review/tasks"
          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Updated")
          end

          click_button("Review informatives")
          within("#informatives_footer") do
            within_fieldset("Do you accept the assessment against informatives?") do
              choose "Agree"
            end

            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Review of informatives updated successfully")
          within("#informatives_section") do
            expect(find(".govuk-tag")).to have_content("Completed")
          end

          click_button("Review informatives")
          click_link("Edit list position")
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
