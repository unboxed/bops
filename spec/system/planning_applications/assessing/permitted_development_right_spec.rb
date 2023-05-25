# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, constraints: [], local_authority: default_local_authority)
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
        expect(page).to have_content(planning_application.full_address)

        within(".govuk-warning-text") do
          expect(page).to have_content("This information will be made publicly available.")
        end

        within("#constraints-section") do
          expect(page).to have_content("Constraints - including Article 4 direction(s)")
          expect(page).to have_content("There are no planning constraints on the application site.")
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
          expect(page).to have_content("This information will be made publicly available.")
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
          create(
            :planning_application,
            :to_be_reviewed,
            local_authority: default_local_authority
          )
        end

        let!(:permitted_development_right) { create(:permitted_development_right, :to_be_reviewed, planning_application:) }

        before do
          create(
            :recommendation,
            planning_application:,
            challenged: true,
            reviewer:,
            reviewed_at: 1.day.ago
          )
        end

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

          choose("Yes")

          fill_in(
            "Describe how permitted development rights have been removed",
            with: "new reason"
          )

          click_button("Save and mark as complete")
          click_link("Make draft recommendation")
          choose("Yes")
          click_button("Update assessment")
          click_link("Review and submit recommendation")
          click_button("Submit recommendation")
          click_link("Log out")
          sign_in(reviewer)
          visit(planning_application_path(planning_application))

          expect(page).to have_list_item_for(
            "Review and sign-off",
            with: "Updated"
          )

          click_link("Review and sign-off")

          expect(page).to have_list_item_for(
            "Review permitted development rights",
            with: "Updated"
          )

          click_link("Review permitted development rights")
          choose("Accept", match: :first)
          click_button("Save and mark as complete")

          expect(page).to have_list_item_for(
            "Review permitted development rights",
            with: "Completed"
          )

          click_link("Application")

          expect(page).to have_list_item_for(
            "Review and sign-off",
            with: "In progress"
          )
        end
      end

      context "when there is an accepted review" do
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
        end
        let!(:permitted_development_right) { create(:permitted_development_right, :accepted, planning_application:) }

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
          create(:permitted_development_right, :review_in_progress, planning_application:)
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
          create(:permitted_development_right, planning_application:)
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

    context "when planning application may be immune" do
      let!(:planning_application) { create(:planning_application, :from_planx_immunity, :in_assessment, local_authority: default_local_authority) }

      it "I can view the information on the permitted development rights page" do
        create(:immunity_detail, planning_application:)

        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Immunity/permitted development rights",
          with: "Not started"
        )

        click_link("Immunity/permitted development rights")

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Immunity/permitted development rights")
        end

        expect(page).to have_current_path(
          new_planning_application_assess_immunity_detail_permitted_development_right_path(planning_application)
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Immunity/permitted development rights")
        end
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

        expect(page).to have_content("Immunity from enforcement")
        expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
        expect(page).to have_content("Have the works been completed? Yes")
        expect(page).to have_content("When were the works completed? 01/02/2015")
        expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
        expect(page).to have_content("Has enforcement action been taken about these changes? No")

        expect(page).to have_content("Assessment summary — Evidence of immunity")
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
