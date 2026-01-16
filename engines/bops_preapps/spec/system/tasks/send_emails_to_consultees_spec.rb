# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send emails to consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
      local_authority:,
      consultation_required: true
    )
  end
  let(:user) { create(:user, local_authority:) }
  let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
  let!(:consultee) { create(:consultee, consultation:, selected: true) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees/send-emails-to-consultees") }

  before do
    sign_in(user)
  end

  it "sends emails to selected consultees and completes the task" do
    clear_enqueued_jobs

    visit "/preapps/#{planning_application.reference}/consultees/send-emails-to-consultees"

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

    visit "/preapps/#{planning_application.reference}/consultees/send-emails-to-consultees"
    click_button "Send emails to consultees"

    expect(page).to have_content("Please select at least one consultee")
    expect(task.reload).to be_not_started
  end

  it "warns when navigating away with unsaved changes to response period", js: true do
    visit "/preapps/#{planning_application.reference}/consultees/send-emails-to-consultees"

    # Clear and set a new value to trigger unsaved changes
    find_field("Set response period").fill_in with: "", fill_options: {clear: :backspace}
    fill_in "Set response period", with: "30"

    dismiss_confirm(text: "You have unsaved changes") do
      click_link "Home"
    end

    expect(page).to have_current_path(/send-emails-to-consultees/)
  end
end
