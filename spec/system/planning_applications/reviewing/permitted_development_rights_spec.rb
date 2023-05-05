# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, constraints: [], local_authority: default_local_authority)
  end

  context "when signed in as a reviewer" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
    end

    before do
      create(:recommendation, planning_application:)
      sign_in reviewer
      Current.user = reviewer
      create(:permitted_development_right, planning_application:)
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
          expect(page).to have_content("Check permitted development rights")
        end

        expect(page).to have_current_path(
          edit_planning_application_review_permitted_development_right_path(planning_application, PermittedDevelopmentRight.last)
        )

        expect(page).to have_content("Check permitted development rights")
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

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
            with: "Completed"
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
          with: "Completed"
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
          with: "Completed"
        )

        click_link "Permitted development rights"

        expect(find_by_id("permitted-development-right-accepted-true-field").selected?).to be(false)
        expect(find_by_id("permitted-development-right-accepted-field").selected?).to be(true)
      end

      context "with previous permitted development right responses" do
        before { PermittedDevelopmentRight.last.update(reviewed_at: Time.zone.now, reviewer:, status: "to_be_reviewed") }

        let!(:permitted_development_right) { create(:permitted_development_right, :to_be_reviewed, planning_application:) }
        let!(:permitted_development_right2) { create(:permitted_development_right, :to_be_reviewed, planning_application:) }

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
                 planning_application:,
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

    context "when planning application may be immune" do
      let!(:planning_application) { create(:planning_application, :from_planx_immunity, :awaiting_determination, local_authority: default_local_authority) }

      it "I can view the information on the review permitted development rights page" do
        immunity_detail = create(:immunity_detail, planning_application:)
        create(:review_immunity_detail, immunity_detail:)
        evidence_group = create(:evidence_group, missing_evidence: true, immunity_detail:)
        create(:document, evidence_group:)

        click_link "Review and sign-off"

        expect(page).to have_list_item_for(
          "Review immunity/permitted development rights",
          with: "Not started"
        )

        click_link "Review immunity/permitted development rights"

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Review")
          expect(page).to have_content("Review immunity/permitted development rights")
        end

        expect(page).to have_current_path(
          edit_planning_application_review_permitted_development_right_path(planning_application, PermittedDevelopmentRight.last)
        )

        expect(page).to have_content("Review immunity/permitted development rights")
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

        expect(page).to have_content("Immunity from enforcement")
        expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
        expect(page).to have_content("Have the works been completed? Yes")
        expect(page).to have_content("When were the works completed? 01/02/2015")
        expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
        expect(page).to have_content("Has enforcement action been taken about these changes? No")

        expect(page).to have_content("Utility bills (1)")
        expect(page).to have_css(".govuk-warning-text__icon")
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
