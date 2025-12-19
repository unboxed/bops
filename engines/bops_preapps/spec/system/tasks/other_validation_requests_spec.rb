# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Other validation requests", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:reference) { planning_application.reference }
  let(:case_record) { planning_application.case_record }
  let(:slug) { "check-and-validate/other-validation-issues/other-validation-requests" }
  let(:task) { case_record.find_task_by_slug_path!(slug) }

  let(:user) { create(:user, local_authority:, name: "Vlad Idator") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  context "when the application has not started" do
    let(:planning_application) { create(:planning_application, :not_started, :pre_application, local_authority:) }

    it "a validation request can be added" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")
      expect(page).to have_selector("h1", text: "Other validation requests")
      expect(page).to have_content("No other validation requests have been added")

      click_link "Add other validation request"
      expect(page).to have_selector("h1", text: "Request other validation change")

      fill_in "Tell the applicant another reason why the application is invalid", with: "Reason for invalidation"
      fill_in "Explain to the applicant how the application can be made valid", with: "Suggestion on fixing"

      click_button "Save request"
      expect(page).to have_content("Change request successfully created")

      within "#other-validation-requests" do
        within "tbody tr:nth-child(1)" do
          within "td:nth-child(1)" do
            expect(page).to have_content("Reason for invalidation")
          end

          within "td:nth-child(2)" do
            expect(page).to have_content("Suggestion on fixing")
          end

          within "td:nth-child(3)" do
            expect(page).to have_content("Vlad Idator")
          end

          within "td:nth-child(4)" do
            expect(page).to have_content("Not sent yet")
          end
        end
      end
    end

    context "and a request has been created" do
      before do
        create(:other_change_validation_request, :pending, planning_application:, user:, reason: "Reason for invalidation", suggestion: "Suggestion on fixing")
      end

      it "then the request can be edited" do
        within ".bops-sidebar" do
          click_link "Other validation requests"
        end

        expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

        within "#other-validation-requests" do
          within "tbody tr:nth-child(1)" do
            within "td:nth-child(1)" do
              expect(page).to have_content("Reason for invalidation")
            end

            within "td:nth-child(2)" do
              expect(page).to have_content("Suggestion on fixing")
            end

            within "td:nth-child(3)" do
              expect(page).to have_content("Vlad Idator")
            end

            within "td:nth-child(4)" do
              expect(page).to have_content("Not sent yet")
            end
          end
        end

        click_link "Reason for invalidation"
        expect(page).to have_selector("h1", text: "View other request")
        expect(page).to have_content("Reason it is invalid: Reason for invalidation")
        expect(page).to have_content("How it can be made valid: Suggestion on fixing")

        click_link "Edit request"
        expect(page).to have_selector("h1", text: "Request other validation change")

        fill_in "Tell the applicant another reason why the application is invalid", with: "Other reason for invalidation"
        fill_in "Explain to the applicant how the application can be made valid", with: "Other suggestion on fixing"

        click_button "Update request"
        expect(page).to have_selector("h1", text: "Other validation requests")
        expect(page).to have_content("Change request successfully updated")

        within "#other-validation-requests" do
          within "tbody tr:nth-child(1)" do
            within "td:nth-child(1)" do
              expect(page).to have_content("Other reason for invalidation")
            end

            within "td:nth-child(2)" do
              expect(page).to have_content("Other suggestion on fixing")
            end

            within "td:nth-child(3)" do
              expect(page).to have_content("Vlad Idator")
            end

            within "td:nth-child(4)" do
              expect(page).to have_content("Not sent yet")
            end
          end
        end
      end

      it "then the request can be deleted" do
        within ".bops-sidebar" do
          click_link "Other validation requests"
        end

        expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

        within "#other-validation-requests" do
          within "tbody tr:nth-child(1)" do
            within "td:nth-child(1)" do
              expect(page).to have_content("Reason for invalidation")
            end

            within "td:nth-child(2)" do
              expect(page).to have_content("Suggestion on fixing")
            end

            within "td:nth-child(3)" do
              expect(page).to have_content("Vlad Idator")
            end

            within "td:nth-child(4)" do
              expect(page).to have_content("Not sent yet")
            end
          end
        end

        click_link "Reason for invalidation"
        expect(page).to have_selector("h1", text: "View other request")
        expect(page).to have_content("Reason it is invalid: Reason for invalidation")
        expect(page).to have_content("How it can be made valid: Suggestion on fixing")

        click_button "Delete request"
        expect(page).to have_selector("h1", text: "Other validation requests")
        expect(page).to have_content("Change request successfully deleted.")
        expect(page).to have_content("No other validation requests have been added")
      end
    end
  end

  context "when the application has been invalidated" do
    let(:planning_application) { create(:planning_application, :invalidated, :pre_application, local_authority:) }

    it "a validation request can be sent" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")
      expect(page).to have_content("No other validation requests have been added")

      click_link "Add other validation request"
      expect(page).to have_selector("h1", text: "Request other validation change")

      fill_in "Tell the applicant another reason why the application is invalid", with: "Reason for invalidation"
      fill_in "Explain to the applicant how the application can be made valid", with: "Suggestion on fixing"

      click_button "Send request"
      expect(page).to have_content("Change request successfully created")

      within "#other-validation-requests" do
        within "tbody tr:nth-child(1)" do
          within "td:nth-child(1)" do
            expect(page).to have_content("Reason for invalidation")
          end

          within "td:nth-child(2)" do
            expect(page).to have_content("Suggestion on fixing")
          end

          within "td:nth-child(3)" do
            expect(page).to have_content("Vlad Idator")
          end

          within "td:nth-child(4)" do
            expect(page).to have_content("Sent")
          end
        end
      end
    end

    context "and a request has been created" do
      context "and it has not been responded to" do
        before do
          create(:other_change_validation_request, :open, planning_application:, user:, reason: "Reason for invalidation", suggestion: "Suggestion on fixing")
        end

        it "then the request can't be edited" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")
          expect(page).not_to have_link("Edit request")
        end

        it "then the request can't be deleted" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")
          expect(page).not_to have_button("Delete request")
        end

        it "then the request can be cancelled" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")

          click_link "Cancel request"
          expect(page).to have_selector("h1", text: "Cancel validation request")

          click_button "Confirm cancellation"
          expect(page).to have_content("Cancel reason can't be blank")

          fill_in "Explain to the applicant why this request is being cancelled", with: "Cancellation reasons"

          click_button "Confirm cancellation"
          expect(page).to have_content("Change request successfully cancelled.")
          expect(page).to have_selector("h1", text: "Other validation requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Cancelled")
              end
            end
          end
        end
      end

      context "and it has been responded to" do
        before do
          create(:other_change_validation_request, :closed, planning_application:, user:, reason: "Reason for invalidation", suggestion: "Suggestion on fixing")
        end

        it "then the request can't be edited" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_link("Edit request")
        end

        it "then the request can't be deleted" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_button("Delete request")
        end

        it "then the request can't be canceled" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_link("Cancel request")
        end
      end
    end
  end

  context "when the application has been validated" do
    let(:planning_application) { create(:planning_application, :not_started, :pre_application, local_authority:) }

    context "and there are no requests" do
      before do
        planning_application.update!(validated_at: planning_application.valid_from_date)
        planning_application.start!
      end

      it "a validation request can't be sent" do
        within ".bops-sidebar" do
          click_link "Other validation requests"
        end

        expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")
        expect(page).to have_content("No other validation requests have been added")
        expect(page).not_to have_link("Add other validation request")
      end
    end

    context "and a request has been created" do
      context "and it has not been responded to" do
        before do
          create(:other_change_validation_request, :open, planning_application:, user:, reason: "Reason for invalidation", suggestion: "Suggestion on fixing")

          planning_application.update!(validated_at: planning_application.valid_from_date)
          planning_application.start!
        end

        it "then the request can't be edited" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")
          expect(page).not_to have_link("Edit request")
        end

        it "then the request can't be deleted" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")
          expect(page).not_to have_button("Delete request")
        end

        it "then the request can be cancelled" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Sent")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "View other request")
          expect(page).to have_content("Reason it is invalid: Reason for invalidation")
          expect(page).to have_content("How it can be made valid: Suggestion on fixing")

          click_link "Cancel request"
          expect(page).to have_selector("h1", text: "Cancel validation request")

          click_button "Confirm cancellation"
          expect(page).to have_content("Cancel reason can't be blank")

          fill_in "Explain to the applicant why this request is being cancelled", with: "Cancellation reasons"

          click_button "Confirm cancellation"
          expect(page).to have_content("Change request successfully cancelled.")
          expect(page).to have_selector("h1", text: "Other validation requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Cancelled")
              end
            end
          end
        end
      end

      context "and it has been responded to" do
        before do
          create(:other_change_validation_request, :closed, planning_application:, user:, reason: "Reason for invalidation", suggestion: "Suggestion on fixing")

          planning_application.update!(validated_at: planning_application.valid_from_date)
          planning_application.start!
        end

        it "then the request can't be edited" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_link("Edit request")
        end

        it "then the request can't be deleted" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_button("Delete request")
        end

        it "then the request can't be canceled" do
          within ".bops-sidebar" do
            click_link "Other validation requests"
          end

          expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")

          within "#other-validation-requests" do
            within "tbody tr:nth-child(1)" do
              within "td:nth-child(1)" do
                expect(page).to have_content("Reason for invalidation")
              end

              within "td:nth-child(2)" do
                expect(page).to have_content("Suggestion on fixing")
              end

              within "td:nth-child(3)" do
                expect(page).to have_content("Vlad Idator")
              end

              within "td:nth-child(4)" do
                expect(page).to have_content("Responded")
              end
            end
          end

          click_link "Reason for invalidation"
          expect(page).to have_selector("h1", text: "Check the response to other request")
          expect(page).to have_content("Some response")
          expect(page).not_to have_link("Cancel request")
        end
      end
    end
  end
end
