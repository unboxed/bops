# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FeeItemsValidation", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  before do
    sign_in assessor
  end

  context "when application is not started" do
    let!(:planning_application) do
      create(
        :planning_application, :not_started,
        local_authority: default_local_authority,
        payment_reference: "PAY1",
        payment_amount: 112.12
      )
    end

    it "I can see a summary breakdown of the fee when I go to validate" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate fee"

      expect(page).to have_content("Check the fee")

      within(".govuk-table") do
        within(".govuk-table__head") do
          expect(page).to have_content("Item")
          expect(page).to have_content("Detail")
        end

        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            expect(page).to have_content("Fee")
            expect(page).to have_content("£112.12")
          end

          within(rows[1]) do
            expect(page).to have_content("Payment Reference")
            expect(page).to have_content("PAY1")
          end

          within(rows[2]) do
            expect(page).to have_content("Description")
            expect(page).to have_content(planning_application.description)
          end
        end
      end
    end

    it "I can validate the fee item" do
      visit planning_application_validation_tasks_path(planning_application)
      within("#fee-validation-task") do
        expect(page).to have_content("Not checked yet")
      end

      click_link "Validate fee"

      within(".govuk-fieldset") do
        expect(page).to have_content("Is the fee valid?")

        within(".govuk-radios") { choose "Yes" }
      end

      click_button "Save"

      expect(page).to have_content("Fee item was marked as valid.")

      within("#fee-validation-task") do
        expect(page).to have_content("Valid")
      end

      expect(planning_application.reload.valid_fee).to be_truthy
      expect(OtherChangeValidationRequest.all.length).to eq(0)
    end

    it "I get validation errors when I omit required information" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate fee"
      click_button "Save"

      expect(page).to have_content("You must first select Yes or No to continue.")

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end
      click_button "Save"
      click_button "Add"

      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Summary can't be blank")
        expect(page).to have_content("Suggestion can't be blank")
      end
    end

    it "I can invalidate the fee item" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate fee"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save"

      expect(page).to have_current_path(
        new_planning_application_other_change_validation_request_path(planning_application, validate_fee: "yes")
      )
      expect(page).to have_content("Request other validation change (Fee)")
      expect(page).to have_content("Application number: #{planning_application.reference}")

      # Display fee item table
      within(".govuk-table") do
        within(".govuk-table__head") do
          expect(page).to have_content("Item")
          expect(page).to have_content("Detail")
        end
      end

      expect(page).to have_content(
        "This request will be added to the application. The requests will not be sent until the application is marked as invalid."
      )

      fill_in "Tell the applicant another reason why the application is invalid.",
              with: "Fee is invalid"
      fill_in "Explain to the applicant how the application can be made valid.",
              with: "Update accurate fee"
      click_button "Add"

      expect(page).to have_content("Other validation change request successfully created.")

      within("#fee-validation-task") do
        expect(page).to have_content("Invalid")
      end

      expect(planning_application.reload.valid_fee).to be_falsey
      expect(OtherChangeValidationRequest.all.length).to eq(1)

      click_link "Validate fee"

      other_change_validation_request = OtherChangeValidationRequest.last
      expect(page).to have_current_path(
        planning_application_other_change_validation_request_path(
          planning_application, other_change_validation_request
        )
      )
      expect(page).to have_content("View other request (fee)")
      expect(page).to have_content("Officer request")

      within(".govuk-inset-text") do
        expect(page).to have_content("Reason it is invalid: Fee is invalid")
        expect(page).to have_content("How it can be made valid: Update accurate fee")
        expect(page).to have_content(other_change_validation_request.created_at)
      end

      within(".govuk-button-group") do
        expect(page).to have_link(
          "Back", href: planning_application_validation_tasks_path(planning_application)
        )
      end
    end

    context "when fee item is invalid" do
      before do
        planning_application.update(valid_fee: false)
      end

      let!(:other_change_validation_request) do
        create(
          :other_change_validation_request, :pending, :fee,
          planning_application: planning_application
        )
      end

      it "I can edit the fee validation request" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Validate fee"
        click_link "Edit request"

        expect(page).to have_current_path(
          edit_planning_application_other_change_validation_request_path(planning_application, other_change_validation_request)
        )

        expect(page).to have_content("Request other validation change (Fee)")
        expect(page).to have_content("Application number: #{planning_application.reference}")

        # Display fee item table
        within(".govuk-table") do
          within(".govuk-table__head") do
            expect(page).to have_content("Item")
            expect(page).to have_content("Detail")
          end
        end

        fill_in "Tell the applicant another reason why the application is invalid.",
                with: "Fee is very invalid"
        fill_in "Explain to the applicant how the application can be made valid.",
                with: "Update better fee"

        within(".govuk-button-group") do
          expect(page).to have_link(
            "Back", href: planning_application_validation_tasks_path(planning_application)
          )
          click_button "Update"
        end

        expect(page).to have_content("Other validation request successfully updated")

        click_link "Validate fee"

        within(".govuk-inset-text") do
          expect(page).to have_content("Reason it is invalid: Fee is very invalid")
          expect(page).to have_content("How it can be made valid: Update better fee")
        end
      end

      it "I can delete the fee validation request" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Validate fee"

        accept_confirm(text: "Are you sure?") do
          click_link("Delete request")
        end

        expect(page).to have_content("Validation request was successfully deleted.")

        within("#fee-validation-task") do
          expect(page).to have_content("Not checked yet")
        end

        expect(planning_application.reload.valid_fee).to be_nil
        expect(OtherChangeValidationRequest.all.length).to eq(0)
      end
    end
  end

  context "when application is invalidated" do
    let!(:planning_application) do
      create(
        :planning_application, :invalidated,
        local_authority: default_local_authority,
        payment_reference: "PAY1",
        payment_amount: 100.21,
        valid_fee: false
      )
    end

    let!(:other_change_validation_request) do
      create(
        :other_change_validation_request, :open, :fee,
        planning_application: planning_application
      )
    end

    it "I can view the request" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate fee"

      expect(page).to have_content("View other request (fee)")
      expect(page).to have_content("Officer request")

      within(".govuk-inset-text") do
        expect(page).to have_content("Reason it is invalid: Incorrect fee")
        expect(page).to have_content("How it can be made valid: You need to pay a different fee")
        expect(page).to have_content(other_change_validation_request.created_at)
      end

      expect(page).to have_content("Applicant has not responded yet")

      within(".govuk-button-group") do
        expect(page).to have_link(
          "Back", href: planning_application_validation_tasks_path(planning_application)
        )
        expect(page).to have_link(
          "Cancel request",
          href: cancel_confirmation_planning_application_other_change_validation_request_path(
            planning_application, other_change_validation_request
          )
        )

        expect(page).not_to have_link("Edit request")
        expect(page).not_to have_link("Delete request")
      end
    end

    it "I can cancel the request" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate fee"
      click_link "Cancel request"

      expect(page).to have_content("Other request to be cancelled (fee)")

      fill_in "Explain to the applicant why this request is being cancelled", with: "Mistake"
      click_button "Confirm cancellation"

      expect(page).to have_content("Validation request was successfuly cancelled.")

      within(".govuk-table.cancelled-requests") do
        within("#other_change_validation_request_#{other_change_validation_request.id}") do
          expect(page).to have_content("Other (fee)")
          expect(page).to have_content("Mistake")
          expect(page).to have_content(other_change_validation_request.reload.cancelled_at)
        end
      end

      expect(planning_application.reload.valid_fee).to be_nil
      expect(OtherChangeValidationRequest.last.state).to eq("cancelled")

      click_link "Validation tasks"

      within("#fee-validation-task") do
        expect(page).to have_content("Not checked yet")
      end
    end

    it "I cannot edit the request" do
      visit edit_planning_application_other_change_validation_request_path(
        planning_application, other_change_validation_request
      )

      expect(page).to have_content("forbidden")
      expect(page).not_to have_link("Edit request")
    end

    context "when applicant has responded" do
      before do
        other_change_validation_request.update(state: "closed", response: "ok")
      end

      let!(:closed_other_change_validation_request) do
        create(
          :other_change_validation_request, :closed, :fee,
          planning_application: planning_application,
          response: "I agree with the fee"
        )
      end

      it "I can see the updated state of the fee request" do
        visit planning_application_validation_tasks_path(planning_application)

        within("#fee-validation-task") do
          expect(page).to have_content("Updated")
        end

        click_link "Validate fee"

        expect(page).to have_content("Check the response to other request (fee)")
        expect(page).to have_content("Officer request")

        inset_texts = page.all(".govuk-inset-text")
        within(inset_texts[0]) do
          expect(page).to have_content("Reason it is invalid: Incorrect fee")
          expect(page).to have_content("How it can be made valid: You need to pay a different fee")
          expect(page).to have_content(closed_other_change_validation_request.updated_at)
        end

        expect(page).to have_content("Applicant response")
        within(inset_texts[1]) do
          expect(page).to have_content("I agree with the fee")
          expect(page).to have_content(closed_other_change_validation_request.updated_at)
        end

        # Fill in bad input
        fill_in "planning_application[payment_amount]", with: "sss"
        click_button("Continue")
        expect(page).to have_content("Payment amount must be a number not exceeding 2 decimal places")

        fill_in "planning_application[payment_amount]", with: "350.22"
        click_button("Continue")

        # Display fee item table
        within(".govuk-table") do
          within(".govuk-table__head") do
            expect(page).to have_content("Item")
            expect(page).to have_content("Detail")
          end
          expect(page).to have_content("£350.22")
        end
        within(".govuk-fieldset") do
          expect(page).to have_content("Is the fee valid?")
        end
      end

      it "I do not see a continue link for non active fee requests" do
        visit planning_application_other_change_validation_request_path(
          planning_application, other_change_validation_request
        )

        expect(page).not_to have_link("Continue")
      end
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not allow you to validate documents" do
      visit planning_application_validation_tasks_path(planning_application)

      within("#fee-validation-task") do
        expect(page).to have_content("Planning application has already been validated")
      end
    end
  end
end
