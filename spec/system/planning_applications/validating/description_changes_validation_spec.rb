# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DescriptionChangesValidation" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
  end

  context "when application is not started" do
    let!(:planning_application) do
      create(
        :planning_application, :not_started, :from_planx_prior_approval,
        local_authority: default_local_authority
      )
    end

    it "I can validate the description" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      within("#check-description-task") do
        expect(page).to have_content("Not started")
      end

      click_link "Check description"

      within(".govuk-fieldset") do
        expect(page).to have_content("Does the description match the development or use in the plans?")

        within(".govuk-radios") { choose "Yes" }
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Description was marked as valid")

      within("#check-description-task") do
        expect(page).to have_content("Completed")
      end

      expect(planning_application.reload.valid_description).to be_truthy
      expect(DescriptionChangeValidationRequest.all.length).to eq(0)

      click_link "Check description"

      expect(page).not_to have_content "Does the description match the development or use in the plans?"

      expect(page).to have_content "Description was marked as valid"
    end

    it "I get validation errors when I omit required information" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check description"
      click_button "Save and mark as complete"

      expect(page).to have_content("Select Yes or No to continue.")

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save and mark as complete"

      fill_in "Enter an amended description", with: ""
      click_button "Update description"

      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Proposed description can't be blank")
      end
    end

    it "I can invalidate the description" do
      expect(PlanningApplicationMailer).to receive(:description_change_mail).and_call_original

      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check description"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save and mark as complete"

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=description_change"
      )
      expect(page).to have_content("Description change")

      fill_in(
        "Enter an amended description",
        with: "My better description"
      )

      expect(page).to have_content("Does this description change require applicant's agreement?")
      choose "Yes, applicant agreement needed"

      click_button "Update description"

      expect(page).to have_content("Description change request successfully sent.")

      within("#check-description-task") do
        expect(page).to have_content("Invalid")
      end

      expect(planning_application.reload.valid_description).to be_falsey
      expect(DescriptionChangeValidationRequest.all.length).to eq(1)

      click_link "Check description"

      description_change_validation_request = DescriptionChangeValidationRequest.last

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/description_change_validation_requests/#{description_change_validation_request.id}"
      )

      expect(page).to have_content("My better description")

      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end

    it "I can mark the task as completed when the description change request has been approved" do
      create(:description_change_validation_request, planning_application:, approved: true, state: "closed")
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within("#check-description-task") do
        expect(page).to have_content("Updated")
        click_link "Check description"
      end

      expect(page).to have_content "Approved"

      click_button "Save and mark as complete"

      expect(page).to have_content("Description was marked as valid")

      within("#check-description-task") do
        expect(page).to have_content("Completed")
      end

      click_link "Check description"

      expect(page).not_to have_content "Does the description match the development or use in the plans?"

      expect(page).to have_content "Description was marked as valid"
    end

    it "I can request another change when the description change request has been rejected" do
      create(:description_change_validation_request, planning_application:, approved: false, state: "closed", rejection_reason: "no")
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within("#check-description-task") do
        expect(page).to have_content("Updated")
        click_link "Check description"
      end

      expect(page).to have_content "Rejected"

      click_link "Request a new description change"

      fill_in(
        "Enter an amended description",
        with: "My better description"
      )

      choose "Yes, applicant agreement needed"
      click_button "Update description"

      within("#check-description-task") do
        expect(page).to have_content("Invalid")
        click_link "Check description"
      end

      expect(page).not_to have_content "Does the description match the development or use in the plans?"

      expect(page).to have_content "Agent or applicant has not yet responded"
    end

    it "I can bypass applicant approval for small changes" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check description"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save and mark as complete"

      field = find("#validation-request-proposed-description-field")
      field.set(field.value + " Extra text")

      expect(page).to have_content("Does this description change require applicant's agreement?")
      choose "No, update description immediately"

      click_button "Update description"

      expect(page).to have_content("Description updated.")

      within("#check-description-task") do
        expect(page).to have_content("Completed")
      end

      expect(planning_application.reload.valid_description).to be_truthy
      expect(DescriptionChangeValidationRequest.all.length).to eq(1)

      visit "/planning_applications/#{planning_application.reference}"
      expect(page).to have_content("Applicant has been notified of the description change.")
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not allow you to validate description" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within("#check-description-task") do
        expect(page).not_to have_link("Check description")
      end
    end
  end

  context "when the application is a pre-application" do
    let(:planning_application) do
      create(
        :planning_application, :not_started, :pre_application, local_authority: default_local_authority
      )
    end

    it "I can request a change and it will be automatically accepted immediately" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check description"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save and mark as complete"

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=description_change"
      )
      expect(page).to have_content("Description change")

      fill_in(
        "Enter an amended description",
        with: "My better description"
      )

      expect(page).not_to have_content("Does this description change require applicant's agreement?")

      click_button "Save and mark as complete"
      expect(page).to have_content("Description updated.")

      within("#check-description-task") do
        expect(page).to have_content("Completed")
      end

      expect(planning_application.reload.valid_description).to be true
      expect(DescriptionChangeValidationRequest.all.length).to eq(1)
      expect(DescriptionChangeValidationRequest.closed.length).to eq(1)

      click_link "Check description"

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/description_changes"
      )

      expect(page).to have_content("My better description")

      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end
  end
end
