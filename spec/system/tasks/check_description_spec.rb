# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description") }

  %i[planning_permission lawfulness_certificate prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :not_started, local_authority:)
      end

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      end

      it_behaves_like "check description task", application_type

      it "completes full validation request flow" do
        expect(task).to be_not_started

        within ".bops-sidebar" do
          click_link "Check description"
        end

        choose "No"
        choose "No, update description immediately"
        fill_in "Enter an amended description", with: "This is an updated description."
        click_button "Save and mark as complete"

        expect(page).to have_content("Description check was successfully saved")
        expect(page).to have_content("Description change")

        expect(task.reload).to be_completed

        expect(planning_application.reload.description).to eq("This is an updated description.")
        expect(page).to have_current_path(
            "/planning_applications/#{planning_application.reference}/check-and-validate/check-application-details/check-description"
          )
      end

      context "when an existing description change request" do
        let(:validation_requests) do
          create(:validation_request, planning_application:, type: "DescriptionChangeValidationRequest", user: user)
        end

        it "allows description change request to be edited and deleted", capybara: true do
          within ".bops-sidebar" do
            click_link "Check description"
          end

          choose "No"
          choose "No, update description immediately"
          fill_in "Enter an amended description", with: "This is an updated description."
          click_button "Save and mark as complete"

          expect(page).to have_content("Description check was successfully saved")
          expect(page).to have_content("Description change")

          expect(task.reload).to be_completed
          visit("/planning_applications/#{planning_application.reference}/check-and-validate/check-application-details/check-description")
          expect(page).to have_content("Description change request")
          click_link "Request a new description change"
          fill_in "Enter an amended description", with: "This is an updated description. Again."

          choose "Yes, applicant agreement needed"
          click_button "Update description"

          expect(page).to have_content("Description change request successfully sent.")

          within ".bops-sidebar" do
            click_link "Check description"
          end

          expect(page).to have_content("This is an updated description. Again.")

          click_link("Cancel description change request")
          fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed."

          click_button "Confirm cancellation"
          expect(page).to have_content("Description change request successfully cancelled")

          expect(planning_application.validation_requests.last.state).to eq("cancelled")
        end
      end
    end
  end
end
