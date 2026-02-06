# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check fee task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-fee") }

  %i[planning_permission pre_application].each do |application_type|
    context "for a #{application_type} case" do
      let(:planning_application) { create(:planning_application, application_type, :not_started, local_authority:) }

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      end

      it "shows the task in the sidebar with not started status" do
        expect(task.status).to eq("not_started")

        within :sidebar do
          expect(page).to have_link("Check fee")
        end
      end

      it "navigates to the task from the sidebar" do
        within :sidebar do
          click_link "Check fee"
        end

        expect(page).to have_content("Check the application fee")
      end

      it "displays the form to check the fee" do
        within :sidebar do
          click_link "Check fee"
        end

        expect(page).to have_content("Check the application fee")
        expect(page).to have_content("This fee was calculated based on the services requested by the applicant.")
        expect(page).to have_content("Payment information")
        expect(page).to have_content("Fee paid")
        expect(page).to have_content("Payment reference")
        expect(page).to have_content("Session ID")
        expect(page).to have_field("Yes")
        expect(page).to have_field("No")
        expect(page).to have_button("Save and mark as complete")
      end

      it "marks task as complete when selecting Yes" do
        expect(task).to be_not_started

        within :sidebar do
          click_link "Check fee"
        end

        choose "Yes"
        click_button "Save and mark as complete"

        expect(page).to have_content("Fee check was successfully saved")
        expect(task.reload).to be_completed
        expect(planning_application.reload.valid_fee).to be true
      end

      it "shows validation request fields when selecting No", js: true do
        expect(task).to be_not_started

        within :sidebar do
          click_link "Check fee"
        end

        choose "No"

        expect(page).to have_field("Tell the applicant why the fee is incorrect")
        expect(page).to have_field("Tell the applicant what they need to do")
      end

      it "shows validation errors when selecting No without reason and suggestion" do
        within :sidebar do
          click_link "Check fee"
        end

        choose "No"
        click_button "Save and mark as complete"

        expect(page).to have_content("Tell the applicant why the fee is incorrect")
        expect(page).to have_content("Tell the applicant what they need to do")
        expect(task.reload).to be_not_started
      end

      it "creates fee change validation request when selecting No with reason and suggestion", js: true do
        expect(task).to be_not_started

        within :sidebar do
          click_link "Check fee"
        end

        choose "No"
        fill_in "Tell the applicant why the fee is incorrect", with: "The fee amount is wrong"
        fill_in "Tell the applicant what they need to do", with: "Please pay the correct amount"
        click_button "Save and mark as complete"

        expect(page).to have_content("Fee check was successfully saved")
        expect(task.reload).to be_completed
        expect(planning_application.reload.valid_fee).to be false
        expect(planning_application.fee_change_validation_requests.count).to eq(1)
      end

      it "shows error when no selection is made" do
        within :sidebar do
          click_link "Check fee"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Select whether the fee is correct")
        expect(task.reload).to be_not_started
      end

      context "when fee change validation request exists" do
        let!(:fee_change_request) do
          create(:fee_change_validation_request,
            :pending,
            planning_application:,
            reason: "Fee is incorrect",
            suggestion: "Please pay the correct fee")
        end

        before do
          task.complete!
        end

        it "shows the validation request on the task page" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("Fee change request sent")
          expect(page).to have_content("Fee is incorrect")
          expect(page).to have_content("Please pay the correct fee")
          expect(page).to have_button("Delete request")
        end

        it "does not show the form when validation request exists" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).not_to have_field("Yes")
          expect(page).not_to have_field("No")
          expect(page).not_to have_button("Save and mark as complete")
        end

        it "resets task to not_started when validation request is deleted", js: true do
          expect(task.reload).to be_completed

          within :sidebar do
            click_link "Check fee"
          end

          accept_confirm do
            click_button "Delete request"
          end

          expect(page).to have_content("Fee change request successfully deleted")
          expect(task.reload).to be_not_started
        end

        it "allows editing the validation request" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Edit request"

          expect(page).to have_content("Edit fee change request")
          expect(page).to have_field("Tell the applicant why the fee is incorrect", with: "Fee is incorrect")
          expect(page).to have_field("Tell the applicant what they need to do", with: "Please pay the correct fee")

          fill_in "Tell the applicant why the fee is incorrect", with: "Updated reason"
          fill_in "Tell the applicant what they need to do", with: "Updated suggestion"
          click_button "Update request"

          expect(page).to have_content("Fee change request successfully updated")
          expect(page).to have_content("Updated reason")
          expect(page).to have_content("Updated suggestion")
        end

        it "shows payment information on edit page" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Edit request"

          expect(page).to have_content("Payment information")
          expect(page).to have_content("Fee paid")
        end

        it "shows guidance on supporting documents" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Edit request"

          expect(page).to have_content("View guidance on supporting documents")
        end
      end

      context "when applicant has responded to fee change request" do
        let!(:fee_change_request) do
          create(:fee_change_validation_request,
            :closed,
            planning_application:,
            reason: "Fee is incorrect",
            suggestion: "Please pay the correct fee",
            response: "I have now paid the correct amount")
        end

        before do
          task.action_required!
          planning_application.update!(valid_fee: false)
        end

        it "shows the task with action_required status" do
          expect(task.reload).to be_action_required
        end

        it "shows the applicant response on the task page" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("Fee change request sent")
          expect(page).to have_content("Applicant response")
          expect(page).to have_content("I have now paid the correct amount")
        end

        it "shows the Yes/No form to re-check the fee" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("Is the fee correct?")
          expect(page).to have_field("Yes")
          expect(page).to have_field("No")
          expect(page).to have_button("Save and mark as complete")
        end

        it "marks fee as valid, updates payment amount, and completes the task" do
          expect(task.reload).to be_action_required

          within :sidebar do
            click_link "Check fee"
          end

          choose "Yes"
          fill_in "Total fee paid", with: "150.00"
          click_button "Save and mark as complete"

          expect(page).to have_content("Fee check was successfully saved")
          expect(task.reload).to be_completed
          expect(planning_application.reload.valid_fee).to be true
          expect(planning_application.payment_amount.to_f).to eq(150.0)
        end
      end

      context "when applicant responded and fee was subsequently marked valid" do
        let!(:fee_change_request) do
          create(:fee_change_validation_request,
            :closed,
            planning_application:,
            reason: "Fee is incorrect",
            suggestion: "Please pay the correct fee",
            response: "I have now paid the correct amount")
        end

        before do
          task.complete!
          planning_application.update!(valid_fee: true)
        end

        it "shows fee info and payment information" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("This fee was calculated based on the services requested by the applicant.")
          expect(page).to have_content("Payment information")
        end

        it "shows Yes pre-checked when editing" do
          within :sidebar do
            click_link "Check fee"
          end

          click_button "Edit"

          expect(page).to have_field("Yes", checked: true)
          expect(page).to have_field("No", checked: false)
        end

        it "does not show the applicant response or validation request details" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).not_to have_content("Applicant response")
          expect(page).not_to have_content("Fee change request sent")
        end
      end

      context "when fee has been marked as valid" do
        before do
          task.complete!
          planning_application.update!(valid_fee: true)
        end

        it "shows payment information" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("This fee was calculated based on the services requested by the applicant.")
          expect(page).to have_content("Payment information")
        end

        it "allows re-checking the fee" do
          within :sidebar do
            click_link "Check fee"
          end

          click_button "Edit"

          expect(page).to have_field("Yes", checked: true)
          expect(page).to have_field("No")
          expect(page).to have_button("Save and mark as complete")
        end

        it "can mark the fee as invalid again", js: true do
          within :sidebar do
            click_link "Check fee"
          end

          click_button "Edit"

          choose "No"
          fill_in "Tell the applicant why the fee is incorrect", with: "Actually the fee is wrong"
          fill_in "Tell the applicant what they need to do", with: "Please pay the correct amount"
          click_button "Save and mark as complete"

          expect(page).to have_content("Fee check was successfully saved")
          expect(planning_application.reload.valid_fee).to be false
          expect(planning_application.fee_change_validation_requests.count).to eq(1)
        end
      end

      context "when documents for fee exemption exist" do
        let!(:document) do
          create(:document, :fee_exemption, planning_application:, created_at: 2.days.ago)
        end

        it "shows documents with file name and date received" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_content("Documents provided by applicant")
          expect(page).to have_content("File name:")
          expect(page).to have_content("Date received:")
          expect(page).to have_content("This document was uploaded by the applicant")
        end
      end

      context "when application is invalidated with fee change request" do
        let!(:fee_change_request) do
          create(:fee_change_validation_request,
            :open,
            planning_application:,
            reason: "Fee is incorrect",
            suggestion: "Please pay the correct fee")
        end

        before do
          task.complete!
          planning_application.update!(status: "invalidated")
        end

        it "shows cancel link when application is invalidated" do
          within :sidebar do
            click_link "Check fee"
          end

          expect(page).to have_link("Cancel request")
          expect(page).not_to have_link("Edit request")
          expect(page).not_to have_button("Delete request")
        end

        it "allows cancelling the validation request and resets task to not started" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Cancel request"

          expect(page).to have_content("Cancel validation request")
          expect(page).to have_content("Fee change validation request")
          expect(page).to have_content("Reason")
          expect(page).to have_content("Fee is incorrect")
          expect(page).to have_content("What the applicant needs to do")
          expect(page).to have_content("Please pay the correct fee")

          fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
          click_button "Confirm cancellation"

          expect(page).to have_content("successfully cancelled")
          expect(fee_change_request.reload).to be_cancelled
          expect(task.reload).to be_not_started
        end

        it "shows validation error when cancelling without providing a reason" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Cancel request"
          click_button "Confirm cancellation"

          expect(page).to have_content("Explain to the applicant why this request is being cancelled")
          expect(fee_change_request.reload).not_to be_cancelled
        end

        it "allows going back from cancel page" do
          within :sidebar do
            click_link "Check fee"
          end

          click_link "Cancel request"
          click_link "Back"

          expect(page).to have_content("Check the application fee")
          expect(page).to have_link("Cancel request")
        end
      end
    end
  end

  context "pre_application-specific features" do
    let(:proposal_details) do
      [
        {
          "question" => "Planning Pre-Application Advice Services",
          "responses" => [{"value" => "Householder (£100)"}],
          "metadata" => {}
        }
      ]
    end
    let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, proposal_details:) }

    before do
      sign_in(user)
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "displays fee calculation for pre-applications" do
      within :sidebar do
        click_link "Check fee"
      end

      expect(page).to have_content("Fee calculation")
      expect(page).to have_content("Householder")
      expect(page).to have_content("£100")
    end
  end
end
