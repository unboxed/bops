# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check neighbour notifications" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:planning_application) do
    create(:planning_application, :planning_permission, :awaiting_determination, local_authority: default_local_authority, user: assessor, make_public: true)
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
      visit "/planning_applications/#{planning_application.id}/review/tasks"

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
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Not started"
        )

        click_link "Check neighbour notifications"

        expect(page).to have_content "Check neighbour notifications"

        expect(page).to have_content("60-62, Commercial Street")

        expect(page).to have_content("the consultation period for this application is 21 days")
        expect(page).to have_content("the last letter was sent 21 days ago")
        expect(page).to have_content("the consultation expiry date for this application is #{consultation.end_date.to_date.to_fs}")

        within_fieldset("Do you accept that notifications have been completed within the correct period?") do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Review of neighbour responses successfully added")

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Completed"
        )
      end

      it "you can send it back for assessment" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Not started"
        )

        click_link "Check neighbour notifications"

        expect(page).to have_content "Check neighbour notifications"

        within_fieldset("Do you accept that notifications have been completed within the correct period?") do
          choose "Return to officer with comment"

          fill_in "Explain why notifications are incomplete.", with: "Notify more people"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Review of neighbour responses successfully added")

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Awaiting changes"
        )

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
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        click_link "Check neighbour notifications"

        expect(page).to have_content "Check neighbour notifications"

        click_button "Save and mark as complete"

        expect(page).to have_content "Select an option"

        choose "Return to officer with comment"

        click_button "Save and mark as complete"

        expect(page).to have_content "Explain to the case officer why"
      end
    end

    context "when the consultation has not been started" do
      it "you can accept that the assessor has notified the correct people" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Not started"
        )

        click_link "Check neighbour notifications"

        expect(page).to have_content "Check neighbour notifications"

        expect(page).to have_content("60-62, Commercial Street")

        expect(page).to have_content("The consultation has not been started")

        within_fieldset("Do you accept that notifications have been completed within the correct period?") do
          choose "Return to officer with comment"
          fill_in "Explain why notifications are incomplete", with: "People need to be consulted"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Review of neighbour responses successfully added")

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Awaiting changes"
        )
      end
    end

    context "when the consultation has not ended" do
      let!(:neighbour) { create(:neighbour, consultation:, address: "60-62, Commercial Street, E16LT") }
      let!(:neighbour_letter) { create(:neighbour_letter, neighbour:, sent_at: 1.day.ago) }

      before do
        consultation.update(start_date: 10.days.ago, end_date: 11.days.from_now)
      end

      it "you can't accept or reject the officer's work" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Check neighbour notifications",
          with: "Not started"
        )

        click_link "Check neighbour notifications"

        expect(page).to have_content "Check neighbour notifications"

        expect(page).to have_content("60-62, Commercial Street")

        expect(page).to have_content("the consultation period for this application is 21 days")
        expect(page).to have_content("the last letter was sent 1 days ago")
        expect(page).to have_content("the consultation expiry date for this application is #{consultation.end_date.to_date.to_fs}")

        within_fieldset("Do you accept that notifications have been completed within the correct period?") do
          choose "Accept"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Consultation expiry date must be in the past. You cannot mark this as complete until the consultation period is complete.")
      end
    end
  end
end
