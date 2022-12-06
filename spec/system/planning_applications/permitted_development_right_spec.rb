# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when signed in as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when planning application is in assessment" do
      it "I can view the information on the permitted development rights page" do
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Not started"
        )

        click_link("Permitted development rights")

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Permitted development rights")
        end

        expect(page).to have_current_path(
          new_planning_application_permitted_development_right_path(planning_application)
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Permitted development rights")
        end
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address.upcase)

        within(".govuk-warning-text") do
          expect(page).to have_content("This information WILL be made public")
        end

        within("#constraints-section") do
          expect(page).to have_content("Constraints - including Article 4 direction(s)")
        end

        within("#planning-history-section") do
          expect(page).to have_content("Planning history")
        end
      end

      it "there is a validation error when submitting an empty text field when selecting 'Yes'" do
        click_link "Check and assess"
        click_link "Permitted development rights"
        choose "Yes"

        click_button "Save and mark as complete"
        within(".govuk-error-summary") do
          expect(page).to have_content "Removed reason can't be blank"
        end

        click_button "Save and come back later"
        within(".govuk-error-summary") do
          expect(page).to have_content "Removed reason can't be blank"
        end
      end

      it "there is no validation error when submitting an empty text field when selecting 'No'" do
        click_link "Check and assess"
        click_link "Permitted development rights"
        choose "No"

        click_button "Save and mark as complete"
        expect(page).to have_content("Permitted development rights response was successfully created")
      end

      it "I can save and come back later when adding or editing the permitted development right" do
        click_link "Check and assess"
        click_link "Permitted development rights"

        choose "Yes"
        fill_in "permitted_development_right[removed_reason]", with: "A reason"
        click_button "Save and come back later"

        expect(page).to have_content("Permitted development rights response was successfully created")

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "In progress"
        )

        click_link("Permitted development rights")

        within(".govuk-warning-text") do
          expect(page).to have_content("This information WILL be made public")
        end

        within("#constraints-section") do
          expect(page).to have_content("Constraints - including Article 4 direction(s)")
        end

        within("#planning-history-section") do
          expect(page).to have_content("Planning history")
        end

        fill_in "permitted_development_right[removed_reason]", with: "Another reason"

        click_button "Save and come back later"
        expect(page).to have_content("Permitted development rights response was successfully updated")

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "In progress"
        )

        click_link("Application")

        expect(list_item("Check and assess")).to have_content("In progress")
      end

      it "I can save and mark as complete when adding the permitted development right" do
        click_link "Check and assess"
        click_link "Permitted development rights"

        choose "Yes"
        fill_in "permitted_development_right[removed_reason]", with: "A reason"
        click_button "Save and mark as complete"

        expect(page).to have_content("Permitted development rights response was successfully created")

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Removed"
        )

        click_link "Permitted development rights"
        expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
        expect(page).to have_content("Yes")
        expect(page).to have_content("A reason")

        click_link "Edit permitted development rights"
        choose "No"
        click_button "Save and mark as complete"

        expect(page).to have_content("Permitted development rights response was successfully updated")

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Checked"
        )

        click_link "Permitted development rights"
        expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
        expect(page).to have_content("No")
      end

      context "when there has been a rejected review" do
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
        end
        let!(:permitted_development_right) { create(:permitted_development_right, :to_be_reviewed, planning_application: planning_application) }

        it "I can respond when there is a reviewer's comment" do
          click_link "Check and assess"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "To be reviewed"
          )

          click_link "Permitted development rights"

          expect(page).to have_text("See previous permitted development checks")
          expect(page).to have_text("#{permitted_development_right.reviewer.name} marked this for review")
          expect(page).to have_text(permitted_development_right.reviewed_at.to_s)
          expect(page).to have_text("Removal reason")
          expect(page).to have_text("Reviewer comment: Comment")

          choose "No"
          click_button "Save and mark as complete"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "Checked"
          )

          click_link "Permitted development rights"

          click_link("Edit permitted development rights")
          expect(page).to have_text("See previous permitted development checks")
          expect(page).to have_text("#{permitted_development_right.reviewer.name} marked this for review")
          expect(page).to have_text(permitted_development_right.reviewed_at.to_s)
          expect(page).to have_text("Removal reason")
          expect(page).to have_text("Reviewer comment: Comment")

          expect(PermittedDevelopmentRight.count).to eq(2)
        end
      end

      context "when there is an accepted review" do
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
        end
        let!(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application: planning_application) }

        it "I cannot edit the response when the reviewer has accepted it" do
          click_link "Check and assess"
          click_link "Permitted development rights"

          expect(page).to have_text("#{permitted_development_right.reviewer.name} accepted this response on #{permitted_development_right.reviewed_at}")

          visit edit_planning_application_permitted_development_right_path(planning_application, permitted_development_right)
          expect(page).to have_text("forbidden")
        end
      end

      context "when there is an incomplete review" do
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
        end

        before do
          create(:permitted_development_right, :review_in_progress, planning_application: planning_application)
        end

        it "I cannot see the reviewer's response if they marked the review as save and come back later" do
          click_link "Check and assess"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "Checked"
          )

          click_link "Permitted development rights"
          expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
          expect(page).to have_content("No")
          expect(page).to have_link("Edit permitted development rights")
        end
      end

      context "when there is an open review" do
        before do
          create(:permitted_development_right, planning_application: planning_application)
        end

        it "I cannot create a new permitted development right request when there is an open response" do
          visit new_planning_application_permitted_development_right_path(planning_application)
          choose "No"
          click_button "Save and mark as complete"
          expect(page).to have_text("Cannot create a permitted development right response when there is already an open response")

          expect(PermittedDevelopmentRight.count).to eq(1)
        end
      end
    end
  end

  context "when signed in as a reviewer" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
    end

    before do
      sign_in reviewer
      Current.user = reviewer
      create(:permitted_development_right, planning_application: planning_application)
      visit planning_application_path(planning_application)
    end

    context "when planning application is awaiting determination" do
      it "I can view the information on the review permitted development rights page" do
        click_link "Review and sign-off"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Not started"
        )

        click_link "Permitted development rights"

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Review")
          expect(page).to have_content("Permitted development rights")
        end

        expect(page).to have_current_path(
          edit_planning_application_review_permitted_development_right_path(planning_application, PermittedDevelopmentRight.last)
        )

        expect(page).to have_content("Check permitted development rights")
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address.upcase)

        expect(page).to have_content("Constraints and history")

        within("#constraints-section") do
          expect(page).to have_content("Constraints")
        end

        within("#planning-history-section") do
          expect(page).to have_content("Historical information related to the property or to adjoining properties")
        end
      end

      context "when permitted development rights have been removed" do
        before do
          planning_application.reload.permitted_development_right.update(removed: true, removed_reason: "A removed reason")
        end

        it "there is a validation error when submitting an empty text field when editing to accept" do
          click_link "Review and sign-off"
          click_link "Permitted development rights"

          radio_buttons = find_all(".govuk-radios__item")
          within(radio_buttons[1]) do
            choose "Edit to accept"
          end
          fill_in "permitted_development_right[removed_reason]", with: ""

          click_button "Save and mark as complete"

          within(".govuk-error-summary") do
            expect(page).to have_content("There is a problem")
            expect(page).to have_content("Removed reason can't be blank")
          end
        end

        it "I can save and mark as complete when adding my review to accept and edit the permitted development right response" do
          click_link "Review and sign-off"
          click_link "Permitted development rights"

          radio_buttons = find_all(".govuk-radios__item")
          within(radio_buttons[1]) do
            choose "Edit to accept"
          end
          fill_in "permitted_development_right[removed_reason]", with: "Edited comment"

          click_button "Save and mark as complete"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "Complete"
          )

          click_link "Permitted development rights"

          expect(PermittedDevelopmentRight.last.reviewer_edited).to be(true)
          expect(page).to have_content("Edited comment")
        end
      end

      context "when permitted development rights have not been removed" do
        it "there is no edit to accept option" do
          click_link "Review and sign-off"
          click_link "Permitted development rights"

          within(".govuk-radios") do
            expect(page).not_to have_content("Edit to accept")
          end
        end
      end

      it "I can save and come back later when adding my review or editing the permitted development right" do
        click_link "Review and sign-off"
        click_link "Permitted development rights"

        choose "Return to officer with comment"
        expect(page).to have_content("Explain to the assessor why this needs reviewing")
        fill_in "permitted_development_right[reviewer_comment]", with: "My review comment"

        click_button "Save and come back later"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "In progress"
        )

        click_link "Permitted development rights"

        choose "Return to officer with comment"
        fill_in "permitted_development_right[reviewer_comment]", with: "My edited review comment"
        click_button "Save and come back later"
        expect(page).to have_content("Permitted development rights response was successfully updated")
      end

      it "I can save and mark as complete when adding my review to accept the permitted development right response" do
        click_link "Review and sign-off"
        click_link "Permitted development rights"

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Complete"
        )

        click_link "Permitted development rights"

        expect(find_by_id("permitted-development-right-accepted-true-field").selected?).to be(true)
        expect(find_by_id("permitted-development-right-accepted-field").selected?).to be(false)
      end

      it "I can save and mark as complete when adding my review to reject the permitted development right response" do
        click_link "Review and sign-off"
        click_link "Permitted development rights"

        choose "Return to officer with comment"
        fill_in "permitted_development_right[reviewer_comment]", with: "My review comment"

        click_button "Save and mark as complete"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Complete"
        )

        click_link "Permitted development rights"

        expect(find_by_id("permitted-development-right-accepted-true-field").selected?).to be(false)
        expect(find_by_id("permitted-development-right-accepted-field").selected?).to be(true)
      end

      context "with previous permitted development right responses" do
        before { PermittedDevelopmentRight.last.update(reviewed_at: Time.zone.now, reviewer: reviewer, status: "to_be_reviewed") }

        let!(:permitted_development_right) { create(:permitted_development_right, :to_be_reviewed, planning_application: planning_application) }
        let!(:permitted_development_right2) { create(:permitted_development_right, :to_be_reviewed, planning_application: planning_application) }

        it "I can see the previous permitted development checks" do
          click_link "Review and sign-off"
          click_link "Permitted development rights"

          expect(page).to have_text("See previous permitted development checks")

          expect(page).to have_text("#{permitted_development_right.reviewer.name} marked this for review")
          expect(page).to have_text(permitted_development_right.reviewed_at.to_s)
          expect(page).to have_text("Removal reason")
          expect(page).to have_text("Reviewer comment: Comment")

          expect(page).to have_text("#{permitted_development_right2.reviewer.name} marked this for review")
          expect(page).to have_text(permitted_development_right2.reviewed_at.to_s)
        end
      end

      context "when reviewer has signed off and agreed with the recommendation" do
        let!(:recommendation) do
          create(:recommendation,
                 planning_application: planning_application,
                 assessor_comment: "New assessor comment",
                 submitted: true)
        end

        before { planning_application.recommendations << recommendation }

        it "I cannot edit the permitted development right" do
          click_link "Review and sign-off"
          click_link "Sign-off recommendation"
          choose("Yes")
          click_button "Save and mark as complete"

          click_link "Permitted development rights"

          choose "Return to officer with comment"
          fill_in "permitted_development_right[reviewer_comment]", with: "My review comment"

          click_button "Save and mark as complete"
          expect(page).to have_content(
            "You agreed with the assessor recommendation, to request any change you must change your decision on the Sign-off recommendation screen"
          )
        end
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit planning_application_path(planning_application)

      expect(page).not_to have_link("Permitted development rights")

      visit new_planning_application_permitted_development_right_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
