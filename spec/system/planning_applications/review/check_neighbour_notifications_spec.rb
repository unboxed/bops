# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check neighbour notifications", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:planning_application) do
    create(:planning_application, :planning_permission, :awaiting_determination, :published, local_authority: default_local_authority, user: assessor)
  end
  let!(:recommendation) { create(:recommendation, planning_application:) }
  let!(:consultation) { planning_application.consultation }

  before do
    allow(Current).to receive(:user).and_return(reviewer)

    sign_in reviewer
  end

  context "when the planning application's type does not include consultation" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: default_local_authority, user: assessor)
    end

    it "does not show the option to check neighbour notifications" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_content("Review and sign-off")

      expect(page).not_to have_content "Check neighbour notifications"
    end
  end

  context "when the planning application's type does include consultation" do
    let!(:neighbour) { create(:neighbour, consultation:, address: "60-62, Commercial Street, E16LT") }
    let!(:neighbour_letter) { create(:neighbour_letter, neighbour:, sent_at: 21.days.ago) }

    context "when the consultation has finished" do
      before do
        consultation.update(start_date: 21.days.ago, end_date: Time.zone.now)
      end

      it "you can accept that the assessor has notified the correct people" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within "#review-neighbour-responses" do
          choose "Agree"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of neighbour responses successfully added")

        within("#review-neighbour-responses") do
          expect(page).to have_content("Completed")
        end
      end

      it "you can send it back for assessment", :capybara do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within "#review-neighbour-responses" do
          choose "Return with comments"
          fill_in "Add a comment", with: "Notify more people"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of neighbour responses successfully added")

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Awaiting changes")
        end

        click_link "Sign off recommendation"

        expect(page).to have_content "You have suggested changes to be made by the officer."

        choose "No (return the case for assessment)"

        fill_in "Explain to the officer why the case is being returned", with: "Notify more"

        click_button "Save and mark as complete"

        expect(page).to have_content "To be reviewed"

        click_link "Application"

        expect(page).to have_list_item_for(
          "Consultees, neighbours and publicity",
          with: "To be reviewed"
        )

        click_link "Consultees, neighbours and publicity"

        expect(page).to have_list_item_for(
          "Send letters to neighbours",
          with: "To be reviewed"
        )

        click_link "Send letters to neighbours"

        expect(page).to have_content "Notify more people"

        click_button "Confirm and send letters"

        click_link "Consultation"

        expect(page).to have_list_item_for(
          "Send letters to neighbours",
          with: "Complete"
        )
      end

      it "shows errors" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within "#review-neighbour-responses" do
          click_button "Save and mark as complete"
        end

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Select an option")
        end

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within("#review-neighbour-responses") do
          choose "Return with comments"
          click_button "Save and mark as complete"
        end

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Explain to the case officer why")
        end
      end
    end

    context "when the consultation has not been started" do
      it "you can accept that the assessor has notified the correct people" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within "#review-neighbour-responses" do
          choose "Return with comments"
          fill_in "Add a comment", with: "People need to be consulted"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of neighbour responses successfully added")

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Awaiting changes")
        end
      end
    end

    context "when the consultation has not ended" do
      let!(:neighbour) { create(:neighbour, consultation:, address: "60-62, Commercial Street, E16LT") }
      let!(:neighbour_letter) { create(:neighbour_letter, neighbour:, sent_at: 1.day.ago) }

      before do
        consultation.update(start_date: 10.days.ago, end_date: 11.days.from_now)
      end

      it "you can't accept or reject the officer's work" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-neighbour-responses") do
          expect(page).to have_content("Check neighbour notifications")
          expect(page).to have_content("Not started")
        end

        click_button "Check neighbour notifications"

        within "#review-neighbour-responses" do
          choose "Agree"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Consultation expiry date must be in the past. You cannot mark this as complete until the consultation period is complete.")
      end
    end
  end
end
