# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  context "when signed in as a reviewer" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
    end

    before do
      create(:recommendation, planning_application:)
      sign_in reviewer
      Current.user = reviewer
      create(:permitted_development_right, planning_application:, status: :to_be_reviewed)
      visit "/planning_applications/#{planning_application.reference}"
    end

    context "when planning application is awaiting determination" do
      context "when permitted development rights have not been removed" do
        it "I can accept the assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Not started")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have not been removed.")

            choose "Agree"
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Complete")
          end
        end

        it "I can reject the assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Not started")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have not been removed.")

            choose "Return with comments"
            click_button "Save and mark as complete"

            expect(page).to have_content("Explain to the case officer why")

            fill_in "Add a comment", with: "Needs more explanation"
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Awaiting changes")
          end
        end

        it "I can save and mark as complete after editing the permitted development rights assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            click_button "Review permitted development rights"
            click_link "Edit"
          end

          expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit")

          choose "Yes"
          fill_in "Describe how permitted development rights have been removed", with: "A removed reason"

          click_button "Save and mark as complete"
          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Updated")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have been removed for the following reasons:")
            expect(page).to have_content("A removed reason")

            choose "Agree"
            click_button "Save and mark as complete"
          end

          expect(PermittedDevelopmentRight.last.reviewer_edited).to be(false)
          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Complete")
          end
        end
      end

      context "when permitted development rights have been removed" do
        before do
          planning_application.reload.permitted_development_right.update(removed: true, removed_reason: "A removed reason")
        end

        it "I can accept the assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Not started")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have been removed for the following reasons:")
            expect(page).to have_content("A removed reason")

            choose "Agree"
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Complete")
          end
        end

        it "I can reject the assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Not started")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have been removed for the following reasons:")
            expect(page).to have_content("A removed reason")

            choose "Return with comments"
            click_button "Save and mark as complete"

            expect(page).to have_content("Explain to the case officer why")

            fill_in "Add a comment", with: "Needs more explanation"
            click_button "Save and mark as complete"
          end

          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Awaiting changes")
          end
        end

        it "I can save and mark as complete after editing the permitted development rights assessment" do
          click_link "Review and sign-off"

          within "#review-permitted-development-rights" do
            click_button "Review permitted development rights"
            click_link "Edit"
          end

          expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit")
          fill_in "Describe how permitted development rights have been removed", with: "Edited comment"
          click_button "Save and mark as complete"

          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Updated")

            click_button "Review permitted development rights"
            expect(page).to have_content("The permitted development rights have been removed for the following reasons:")
            expect(page).to have_content("Edited comment")

            choose "Agree"
            click_button "Save and mark as complete"
          end

          expect(PermittedDevelopmentRight.last.reviewer_edited).to be(false)
          expect(page).to have_content("Permitted development rights response was successfully updated")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Complete")
          end
        end
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    before do
      sign_in reviewer
    end

    it "does not allow me to visit the page" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_content("The planning application must be validated before reviewing can begin")
      expect(page).not_to have_link("Review and sign-off", href: "/planning_applications/#{planning_application.reference}/review/tasks")
    end
  end
end
