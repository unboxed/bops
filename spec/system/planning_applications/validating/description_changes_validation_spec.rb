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
      visit "/planning_applications/#{planning_application.id}/validation/tasks"
      within("#description-validation-task") do
        expect(page).to have_content("Not started")
      end

      click_link "Check description"

      within(".govuk-fieldset") do
        expect(page).to have_content("Does the description match the development or use in the plans?")

        within(".govuk-radios") { choose "Yes" }
      end

      click_button "Save"

      expect(page).to have_content("Description was marked as valid")

      within("#description-validation-task") do
        expect(page).to have_content("Valid")
      end

      expect(planning_application.reload.valid_description).to be_truthy
      expect(DescriptionChangeValidationRequest.all.length).to eq(0)
    end

    it "I get validation errors when I omit required information" do
      visit "/planning_applications/#{planning_application.id}/validation/tasks"
      click_link "Check description"
      click_button "Save"

      expect(page).to have_content("Select Yes or No to continue.")

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end
      click_button "Save"
      click_button "Send"

      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Proposed description can't be blank")
      end
    end

    it "I can invalidate the description" do
      expect(PlanningApplicationMailer).to receive(:description_change_mail).and_call_original

      visit "/planning_applications/#{planning_application.id}/validation/tasks"
      click_link "Check description"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save"

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.id}/validation/validation_requests/new?type=description_change"
      )
      expect(page).to have_content("Description change")
      expect(page).to have_content("Application number: #{planning_application.reference}")

      fill_in(
        "Suggest a new application description",
        with: "My better description"
      )

      click_button "Send"

      expect(page).to have_content("Description change request successfully sent.")

      within("#description-validation-task") do
        expect(page).to have_content("Invalid")
      end

      expect(planning_application.reload.valid_description).to be_falsey
      expect(DescriptionChangeValidationRequest.all.length).to eq(1)

      click_link "Check description"

      description_change_validation_request = DescriptionChangeValidationRequest.last

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.id}/validation/description_change_validation_requests/#{description_change_validation_request.id}"
      )

      expect(page).to have_content("My better description")

      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.id}/validation/tasks")
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not allow you to validate documents" do
      visit "/planning_applications/#{planning_application.id}/validation/tasks"

      within("#description-validation-task") do
        expect(page).to have_content("Planning application has already been validated")
      end
    end
  end
end
