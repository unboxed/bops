# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, :ldc_existing, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when signed in as an assessor" do
    before do
      create(:decision, :ldc_granted)
      create(:decision, :ldc_refused)

      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    context "when planning application is in assessment" do
      it "I can view the information on the permitted development rights page" do
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Permitted development rights",
          with: "Not started"
        )

        click_link("Permitted development rights")

        expect(page).to have_current_path(
          "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit"
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Permitted development rights")
        end
        expect(page).to have_content(planning_application.full_address)

        within(".govuk-warning-text") do
          expect(page).to have_content("This information will be made publicly available.")
        end

        within("#constraints-section") do
          expect(page).to have_content("Constraints - including Article 4 direction(s)")
          expect(page).to have_content("There are no planning constraints on the application site.")
        end

        within("#planning-history-section") do
          expect(page).to have_selector("h2", text: "Site history")
          expect(page).to have_content("There is no site history for this property.")
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
      end

      it "there is no validation error when submitting an empty text field when selecting 'No'" do
        click_link "Check and assess"
        click_link "Permitted development rights"
        choose "No"

        click_button "Save and mark as complete"
        expect(page).to have_content("Permitted development rights response was successfully updated")
      end

      it "I can save and mark as complete when adding the permitted development right" do
        click_link "Check and assess"
        click_link "Permitted development rights"

        choose "Yes"
        fill_in "permitted_development_right[removed_reason]", with: "A reason"
        click_button "Save and mark as complete"

        expect(page).to have_content("Permitted development rights response was successfully updated")

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
          with: "Completed"
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

          within_fieldset("Have the permitted development rights relevant for this application been removed?") do
            choose "No"
          end
          click_button "Save and mark as complete"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "Updated"
          )

          click_link "Permitted development rights"

          click_link("Edit permitted development rights")
          expect(page).to have_text("See previous permitted development checks")
          expect(page).to have_text("#{permitted_development_right.reviewer.name} marked this for review")
          expect(page).to have_text(permitted_development_right.reviewed_at.to_s)
          expect(page).to have_text("Removal reason")
          expect(page).to have_text("Reviewer comment: Comment")

          expect(PermittedDevelopmentRight.count).to eq(2)

          within_fieldset("Have the permitted development rights relevant for this application been removed?") do
            choose "Yes"
          end

          fill_in(
            "Describe how permitted development rights have been removed",
            with: "new reason"
          )

          click_button("Save and mark as complete")
          click_link("Make draft recommendation")
          within_fieldset("What is your recommendation?") do
            choose "Granted"
          end
          click_button("Update assessment")
          click_link("Review and submit recommendation")
          click_button("Submit recommendation")
          click_link("Log out")
          sign_in(reviewer)
          visit "/planning_applications/#{planning_application.reference}"

          expect(page).to have_list_item_for(
            "Review and sign-off",
            with: "Updated"
          )

          click_link("Review and sign-off")

          within "#review-permitted-development-rights" do
            expect(page).to have_selector("h3", text: "Review permitted development rights")
            expect(page).to have_selector("strong", text: "Updated")

            click_button("Review permitted development rights")
            choose "Agree"
            click_button("Save and mark as complete")
          end

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
        let!(:permitted_development_right) { planning_application.permitted_development_right }

        before do
          permitted_development_right.update!(status: "complete", accepted: true, reviewer:, reviewed_at: Time.current)
        end

        it "I cannot edit the response when the reviewer has accepted it" do
          click_link "Check and assess"
          click_link "Permitted development rights"

          expect(page).to have_text("#{permitted_development_right.reviewer.name} accepted this response on #{permitted_development_right.reviewed_at}")

          visit "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit"

          expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights")
          expect(page).to have_text("The assessment of permitted development rights has been accepted")
        end
      end

      context "when there is an incomplete review" do
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination, local_authority: default_local_authority)
        end
        let!(:permitted_development_right) { planning_application.permitted_development_right }

        before do
          permitted_development_right.update!(status: :complete, reviewer:, review_status: :review_in_progress, reviewer_comment: "Comment")
        end

        it "I cannot see the reviewer's response if they marked the review as save and come back later" do
          click_link "Check and assess"

          expect(page).to have_list_item_for(
            "Permitted development rights",
            with: "Completed"
          )

          click_link "Permitted development rights"
          expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
          expect(page).to have_content("No")
          expect(page).to have_link("Edit permitted development rights")
        end
      end
    end

    context "when planning application may be immune" do
      let!(:planning_application) { create(:planning_application, :from_planx_immunity, :in_assessment, local_authority: default_local_authority) }

      it "I can view the information on the permitted development rights page" do
        create(:immunity_detail, planning_application:)

        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Assess immunity",
          with: "Not started"
        )

        click_link("Assess immunity")

        expect(page).to have_current_path(
          "/planning_applications/#{planning_application.reference}/assessment/assess_immunity_detail_permitted_development_rights/new"
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Assess immunity")
        end

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
      visit "/planning_applications/#{planning_application.reference}"

      expect(page).not_to have_link("Permitted development rights")

      visit "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights"

      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end

  context "when application type is planning permission" do
    let!(:planning_application) do
      create(:planning_application, :planning_permission, local_authority: default_local_authority)
    end

    it "returns 404" do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"

      expect(page).not_to have_link("Permitted development rights")

      expect do
        visit "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights"
        expect(page).to have_selector("h1", text: "Does not exist")
      end.to raise_error(BopsCore::Errors::NotFoundError, "Permitted development rights are not applicable to this planning application")
    end
  end
end
