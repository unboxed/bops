# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FeeItemsValidation", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
  end

  context "when application is not started" do
    let(:proposal_details) do
      [
        {
          question: "What type of planning application are you making?",
          responses: [{value: "Existing changes"}],
          metadata: {section_name: "fee-related"}
        },
        {
          question: "What type of changes does the project involve?",
          responses: [{value: "Alteration"}],
          metadata: {
            section_name: "fee-related",
            policy_refs: [
              {text: "The Town and Country Planning Order 2015"},
              {url: "https://www.example.com/planning/policy/1"}
            ]
          }
        }
      ]
    end

    let(:fee_calculation) do
      FeeCalculation.new(payable_fee: 96.00)
    end

    let!(:planning_application) do
      create(
        :planning_application, :not_started, :from_planx_prior_approval,
        local_authority: default_local_authority,
        payment_reference: "PAY1",
        fee_calculation:,
        proposal_details:
      )
    end

    it "displays the planning application address and reference" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"

      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.reference)
    end

    it "I can see a summary breakdown of the fee when I go to validate" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"

      expect(page).to have_content("Check fee")

      table = find_all(".govuk-table").first

      within(table) do
        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            expect(page).to have_content("Fee Paid")
            expect(page).to have_content("£96.00")
          end

          within(rows[1]) do
            expect(page).to have_content("Payment Reference")
            expect(page).to have_content("PAY1")
          end

          within(rows[2]) do
            expect(page).to have_content("Session ID")
            expect(page).to have_content("21161b70-0e29-40e6-9a38-c42f61f25ab9")
          end
        end
      end
    end

    it "renders fee related proposal details" do
      visit "/planning_applications/#{planning_application.reference}/validation/fee_items"

      expect(page).to have_content("Related questions and answers from PlanX")

      table = find_all(".govuk-table").last

      within(table) do
        rows = find_all(".govuk-table__row")

        expect(rows[0]).to have_content(
          "What type of planning application are you making?"
        )

        within(rows[1]) do
          expect(page).to have_content(
            "What type of changes does the project involve?"
          )

          find("span", text: "Related legislation").click

          expect(page).to have_content("The Town and Country Planning Order 2015")

          expect(page).to have_link(
            "https://www.example.com/planning/policy/1",
            href: "https://www.example.com/planning/policy/1"
          )
        end
      end
    end

    it "I can validate the fee item" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      within("#fee-validation-task") do
        expect(page).to have_content("Not started")
      end

      click_link "Check fee"

      within(".govuk-fieldset") do
        expect(page).to have_content("Is the fee valid?")

        within(".govuk-radios") { choose "Yes" }
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Fee item was marked as valid.")

      within("#fee-validation-task") do
        expect(page).to have_content("Completed")
      end

      expect(planning_application.reload.valid_fee).to be_truthy
      expect(FeeChangeValidationRequest.all.length).to eq(0)
    end

    it "I get validation errors when I omit required information" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"
      click_button "Save and mark as complete"

      expect(page).to have_content("Select Yes or No to continue.")

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end
      click_button "Save and mark as complete"
      click_button "Save request"

      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Provide a reason for changes")
        expect(page).to have_content("Suggestion can't be blank")
      end
    end

    it "I can invalidate the fee item" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"

      within(".govuk-fieldset") do
        within(".govuk-radios") { choose "No" }
      end

      click_button "Save and mark as complete"

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=fee_change"
      )
      expect(page).to have_content("Request other validation change (fee)")

      within(".govuk-details__summary") do
        expect(page).to have_content(
          "View guidance on supporting documents"
        )
      end

      expect(page).to have_content(
        "This request will be added to the application. The requests will not be sent until the application is marked as invalid."
      )

      fill_in(
        "Tell the applicant why the fee is incorrect",
        with: "Fee is invalid"
      )

      fill_in(
        "Tell the applicant what they need to do",
        with: "Update accurate fee"
      )

      click_button "Save request"

      expect(page).to have_content("Fee change request successfully created.")

      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 1")
      end
      within("#fee-validation-task") do
        expect(page).to have_content("Invalid")
      end

      expect(planning_application.reload.valid_fee).to be_falsey
      expect(FeeChangeValidationRequest.all.length).to eq(1)

      click_link "Check fee"

      other_change_validation_request = FeeChangeValidationRequest.last

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/fee_change_validation_requests/#{other_change_validation_request.id}"
      )
      expect(page).to have_content("View fee change request")
      expect(page).to have_content("Officer request")

      within(".govuk-inset-text") do
        expect(page).to have_content("Reason fee is invalid: Fee is invalid")
        expect(page).to have_content("What the applicant needs to do Update accurate fee")
        expect(page).to have_content(other_change_validation_request.created_at.to_fs)
      end

      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end

    context "when fee item is invalid" do
      before do
        planning_application.update(valid_fee: false)
      end

      let!(:other_change_validation_request) do
        create(
          :fee_change_validation_request, :pending,
          planning_application:
        )
      end

      it "I can edit the fee validation request" do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Check fee"
        click_link "Edit request"

        expect(page).to have_current_path(
          "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{other_change_validation_request.id}/edit"
        )

        expect(page).to have_content("Request other validation change (fee)")

        # Display fee item table
        expect(page).to have_css(".fee-table")

        fill_in(
          "Tell the applicant why the fee is incorrect",
          with: "Fee is very invalid"
        )

        fill_in(
          "Tell the applicant what they need to do",
          with: "Update better fee"
        )

        within(".govuk-button-group") do
          click_button "Update"
        end

        expect(page).to have_content("Fee change request successfully updated")

        click_link "Check fee"

        within(".govuk-inset-text") do
          expect(page).to have_content("Reason fee is invalid: Fee is very invalid")
          expect(page).to have_content("What the applicant needs to do Update better fee")
        end
      end

      it "I can delete the fee validation request", :capybara do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Check fee"

        accept_confirm(text: "Are you sure?") do
          click_link("Delete request")
        end

        expect(page).to have_content("Fee change request successfully deleted.")

        within("#invalid-items-count") do
          expect(page).to have_content("Invalid items 0")
        end
        within("#fee-validation-task") do
          expect(page).to have_content("Not started")
        end

        expect(planning_application.reload.valid_fee).to be_nil
        expect(FeeChangeValidationRequest.all.length).to eq(0)
      end
    end

    context "when no fee paid" do
      let!(:planning_application) do
        create(
          :planning_application, :not_started,
          local_authority: default_local_authority,
          payment_reference: nil,
          payment_amount: nil,
          proposal_details:
        )
      end

      it "shows the fee as £0.00" do
        visit "/planning_applications/#{planning_application.reference}/validation/fee_items"

        expect(page).to have_row_for("Fee Paid", with: "£0.00")
        expect(page).to have_row_for("Payment Reference", with: "Exempt")
      end
    end
  end

  context "when application is invalidated" do
    let!(:planning_application) do
      create(
        :planning_application, :invalidated,
        local_authority: default_local_authority,
        payment_reference: "PAY1",
        payment_amount: 100.00,
        valid_fee: false
      )
    end

    let!(:other_change_validation_request) do
      create(
        :fee_change_validation_request, :open,
        planning_application:
      )
    end

    it "I can view the request" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"

      expect(page).to have_content("View fee change request")
      expect(page).to have_content("Officer request")

      within(".govuk-inset-text") do
        expect(page).to have_content("Reason fee is invalid")
        expect(page).to have_content("Incorrect fee")
        expect(page).to have_content("What the applicant needs to do")
        expect(page).to have_content("You need to pay a different fee")
        expect(page).to have_content(other_change_validation_request.created_at.to_fs)
      end

      expect(page).to have_content("Applicant has not responded to the latest request")

      within(".govuk-button-group") do
        expect(page).to have_link(
          "Cancel request",
          href: cancel_confirmation_planning_application_validation_validation_request_path(
            planning_application, other_change_validation_request
          )
        )

        expect(page).not_to have_link("Edit request")
        expect(page).not_to have_link("Delete request")
      end
    end

    it "I can cancel the request" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Check fee"
      click_link "Cancel request"

      expect(page).to have_content("Other request to be cancelled (fee)")

      fill_in "Explain to the applicant why this request is being cancelled", with: "Mistake"
      click_button "Confirm cancellation"

      expect(page).to have_content("Fee change request successfully cancelled.")

      within(".govuk-table.cancelled-requests") do
        within("#fee_change_validation_request_#{other_change_validation_request.id}") do
          expect(page).to have_content("Fee change")
          expect(page).to have_content("Mistake")
          expect(page).to have_content(other_change_validation_request.reload.cancelled_at.to_fs)
        end
      end

      expect(planning_application.reload.valid_fee).to be_nil
      expect(FeeChangeValidationRequest.last.state).to eq("cancelled")

      click_link "Validation tasks"

      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 0")
      end
      within("#fee-validation-task") do
        expect(page).to have_content("Not started")
      end
    end

    it "I cannot edit the request" do
      visit "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{other_change_validation_request.id}/edit"

      expect(page).to have_content("forbidden")
      expect(page).not_to have_link("Edit request")
    end

    context "when applicant has responded" do
      let(:fee_exemption_document) { create(:document, :with_file, planning_application:, tags: %w[disabilityExemptionEvidence]) }

      before do
        travel_to Time.zone.local(2021, 1, 1)

        other_change_validation_request.update(state: "closed", response: "ok")

        closed_other_change_validation_request.supporting_documents << fee_exemption_document
      end

      let(:closed_other_change_validation_request) do
        create(
          :fee_change_validation_request, :closed,
          planning_application:,
          response: "I agree with the fee"
        )
      end

      it "I can see the updated state of the fee request", :capybara do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"

        within("#fee-validation-task") do
          expect(page).to have_content("Updated")
        end

        click_link "Check fee"

        expect(page).to have_content("Check applicant response and update fee paid")
        expect(page).to have_content("Officer request")

        inset_texts = page.all(".govuk-inset-text")
        within(inset_texts[0]) do
          expect(page).to have_content("Reason fee is invalid:")
          expect(page).to have_content("Incorrect fee")
          expect(page).to have_content("What the applicant needs to do")
          expect(page).to have_content("You need to pay a different fee")
          expect(page).to have_content(closed_other_change_validation_request.updated_at.to_fs)
        end

        expect(page).to have_content("Documents provided by applicant")
        within(".govuk-table__body") do
          expect(page).to have_link("View in new window")
          expect(page).to have_content("File name: proposed-floorplan.png")
          expect(page).to have_content("Date received: 1 January 2021")
          expect(page).to have_content("This document was uploaded by the applicant")
        end

        expect(page).to have_content("Applicant response")
        within(inset_texts[1]) do
          expect(page).to have_content("I agree with the fee")
          expect(page).to have_content(closed_other_change_validation_request.updated_at.to_fs)
        end

        expect(page).to have_content("Confirm total fee paid")
        expect(page).to have_content("check that the correct fee has been received")
        expect(page).to have_content("update the total fee paid")
        expect(page).to have_field("planning_application[payment_amount]", with: "100.00")

        fill_in "planning_application[payment_amount]", with: "350.22"
        click_button("Mark as valid")

        expect(page).to have_content "Planning application payment amount was successfully updated."

        within("#fee-validation-task") do
          expect(page).to have_content("Completed")
        end

        visit "/planning_applications/#{planning_application.reference}/audits"

        # Check audit log
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Requested fee updated")
          expect(page).to have_content("Changed from: £100.00 Changed to: £350.22")
        end
      end

      it "I do not see a continue link for non active fee requests" do
        visit "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{other_change_validation_request.id}"

        expect(page).not_to have_link("Continue")
      end
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not allow you to validate documents" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within("#fee-validation-task") do
        expect(page).not_to have_link("Check fee")
      end
    end
  end
end
