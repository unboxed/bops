# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View consultee responses task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  %i[prior_approval planning_permission].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, :published, local_authority:)
      end
      let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
      let(:slug) { "consultees-neighbours-and-publicity/consultees/view-consultee-responses" }
      let(:task) { planning_application.case_record.find_task_by_slug_path!(slug) }

      before do
        sign_in(user)
      end

      context "when there are no consultees" do
        it "displays a message that no consultees have been added" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          expect(page).to have_content("View consultee responses")
          expect(page).to have_content("No consultees have been added yet")
        end
      end

      context "when there are consultees" do
        let!(:consultee_not_consulted) do
          create(:consultee, consultation:, name: "Environment Agency", status: :not_consulted)
        end

        let!(:consultee_awaiting) do
          create(:consultee, consultation:, name: "Historic England", status: :awaiting_response)
        end

        it "displays the response summary panel" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          expect(page).to have_content("Response summary")
          expect(page).to have_content("Total consultees")
          expect(page).to have_content("Responded")
          expect(page).to have_content("Awaiting response")
          expect(page).to have_content("Not consulted")
        end

        it "displays the consultee tabs" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          expect(page).to have_content("Consultee responses")
          expect(page).to have_content("All (2)")
          expect(page).to have_content(consultee_not_consulted.name)
          expect(page).to have_content(consultee_awaiting.name)
        end

        it "saves and marks the task as complete" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          click_button "Save and mark as complete"

          expect(page).to have_content("Consultee responses review was successfully saved")
          expect(task.reload).to be_completed
        end

        it "saves as draft and marks task in progress" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          click_button "Save changes"

          expect(page).to have_content("Consultee responses review draft was saved")
          expect(task.reload).to be_in_progress
        end

        it "uploads a new response inside the task sidebar" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"
          expect(page).to have_selector(:sidebar)

          within "#consultee-tab-all" do
            within(".consultee-panel", text: consultee_awaiting.name) do
              click_link "Upload new response"
            end
          end

          expect(page).to have_selector("h1", text: "Upload consultee response")
          expect(page).to have_selector(:sidebar)

          choose "No objection"
          fill_in "Response", with: "Happy for this to proceed"

          click_button "Save response"

          expect(page).to have_selector("h1", text: "View consultee responses")
          expect(page).to have_selector(:sidebar)
          expect(page).to have_content("Response was successfully uploaded")
        end

        it "redacts and publishes a response inside the task sidebar" do
          consultee_awaiting.responses.create!(
            name: "Jo Bloggs",
            response: "Original response text",
            summary_tag: "approved",
            received_at: Time.current
          )

          visit "/planning_applications/#{planning_application.reference}/#{slug}"
          expect(page).to have_selector(:sidebar)

          within "#consultee-tab-all" do
            click_link "View all responses (1)"
          end

          expect(page).to have_selector("h1", text: "View consultee response")
          expect(page).to have_selector(:sidebar)

          within "#consultee-responses" do
            click_link "Redact and publish"
          end

          expect(page).to have_selector("h1", text: "Redact comment")
          expect(page).to have_selector(:sidebar)

          fill_in "Redacted comment", with: "Redacted response text"
          click_button "Save and publish"

          expect(page).to have_selector("h1", text: "View consultee responses")
          expect(page).to have_selector(:sidebar)
          expect(page).to have_content("Response was successfully published")
        end

        it "returns to the task page with the sidebar from the back button" do
          visit "/planning_applications/#{planning_application.reference}/#{slug}"

          within "#consultee-tab-all" do
            within(".consultee-panel", text: consultee_awaiting.name) do
              click_link "Upload new response"
            end
          end

          expect(page).to have_selector("h1", text: "Upload consultee response")
          click_link "Back"

          expect(page).to have_selector("h1", text: "View consultee responses")
          expect(page).to have_selector(:sidebar)
        end
      end
    end
  end
end
