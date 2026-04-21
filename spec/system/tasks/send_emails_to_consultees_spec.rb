# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send emails to consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  %i[prior_approval planning_permission].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, :published, local_authority:)
      end
      let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
      let!(:consultee) { create(:consultee, consultation:, selected: true) }
      let(:slug) { "consultees-neighbours-and-publicity/consultees/send-emails-to-consultees" }
      let(:task) { planning_application.case_record.find_task_by_slug_path!(slug) }

      before do
        sign_in(user)
      end

      it "sends emails to selected consultees and completes the task" do
        clear_enqueued_jobs

        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        expect(page).to have_content("Send emails to consultees")
        check "Select consultee"

        expect do
          click_button "Send emails to consultees"

          expect(page).to have_content("Emails have been sent to the selected consultees")
        end.to have_enqueued_job(SendConsulteeEmailJob).once

        expect(task.reload).to be_completed
        expect(consultee.reload.status).to eq("sending")
      end

      it "shows validation errors when no consultees are selected" do
        consultee.update!(selected: false)

        visit "/planning_applications/#{planning_application.reference}/#{slug}"
        click_button "Send emails to consultees"

        expect(page).to have_content("Please select at least one consultee")
        expect(task.reload).to be_not_started
      end

      it "allows setting a custom response period" do
        clear_enqueued_jobs

        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        check "Select consultee"

        find_field("Set response period").fill_in with: "", fill_options: {clear: :backspace}
        fill_in "Set response period", with: "30"

        click_button "Send emails to consultees"

        expect(page).to have_content("Emails have been sent to the selected consultees")
        expect(consultation.reload.end_date).to be_present
      end

      it "shows the consultees table with correct details" do
        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        expect(page).to have_content(consultee.name)
        expect(page).to have_css("#consultees")
      end

      it "warns when navigating away with unsaved changes to response period", :js do
        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        find_field("Set response period").fill_in with: "", fill_options: {clear: :backspace}
        fill_in "Set response period", with: "30"

        dismiss_confirm(text: "You have unsaved changes") do
          click_link "Home"
        end

        expect(page).to have_current_path(/send-emails-to-consultees/)
      end
    end
  end
end
