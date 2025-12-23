# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Determine consultation requirement task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees/determine-consultation-requirement") }

  before do
    sign_in(user)
  end

  it "shows the task with not started status" do
    expect(task.status).to eq("not_started")
  end

  it "navigates to the task page" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    expect(page).to have_content("Determine consultation requirement")
  end

  it "displays the form with Yes and No options" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    expect(page).to have_content("Is consultation required?")
    expect(page).to have_content("Select \"Yes\" to unlock consultation tasks or \"No\" to skip them for this case.")
    expect(page).to have_field("Yes")
    expect(page).to have_field("No")
    expect(page).to have_button("Save and mark as complete")
  end

  it "shows error when no selection is made" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    click_button "Save and mark as complete"

    expect(page).to have_content("Determine if consultation is required")
    expect(task.reload).to be_not_started
  end

  it "marks task as complete when selecting Yes" do
    expect(task).to be_not_started

    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Consultation requirement was successfully updated")
    expect(task.reload).to be_completed
    expect(planning_application.reload.consultation_required).to be true
  end

  it "marks task as complete when selecting No" do
    expect(task).to be_not_started

    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Consultation requirement was successfully updated")
    expect(task.reload).to be_completed
    expect(planning_application.reload.consultation_required).to be false
  end

  it "stays on the task page after completion" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement")
  end

  it "shows correct breadcrumb navigation" do
    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).to have_link("Consultation")
  end

  it "hides save button when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

    expect(page).not_to have_button("Save and mark as complete")
  end

  context "when consultation_required is already set to true" do
    before do
      planning_application.update!(consultation_required: true)
    end

    it "pre-selects the Yes option" do
      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).to have_checked_field("Yes")
    end
  end

  context "when consultation_required is already set to false" do
    before do
      planning_application.update!(consultation_required: false)
    end

    it "pre-selects the No option" do
      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).to have_checked_field("No")
    end
  end

  context "when consultees exist and changing to No" do
    let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }

    before do
      planning_application.update!(consultation_required: true)
      create(:consultee, consultation:)
    end

    it "shows warning about removing consultees" do
      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).to have_selector(
        ".govuk-warning-text",
        text: "Changing this answer to \"No\" will remove all consultees"
      )
    end
  end

  describe "consultation task visibility" do
    let(:consultees_section) { planning_application.case_record.find_task_by_slug_path!("consultees") }
    let(:add_consultees_task) { consultees_section.tasks.find_by(slug: "add-and-assign-consultees") }
    let(:send_emails_task) { consultees_section.tasks.find_by(slug: "send-emails-to-consultees") }

    it "shows hidden consultation tasks when selecting Yes" do
      expect(add_consultees_task).to be_hidden
      expect(send_emails_task).to be_hidden

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      choose "Yes"
      click_button "Save and mark as complete"

      expect(add_consultees_task.reload).not_to be_hidden
      expect(send_emails_task.reload).not_to be_hidden
    end

    it "keeps consultation tasks hidden when selecting No" do
      expect(add_consultees_task).to be_hidden
      expect(send_emails_task).to be_hidden

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      choose "No"
      click_button "Save and mark as complete"

      expect(add_consultees_task.reload).to be_hidden
      expect(send_emails_task.reload).to be_hidden
    end

    context "when consultation was previously required" do
      before do
        planning_application.update!(consultation_required: true)
        add_consultees_task.update!(hidden: false)
        send_emails_task.update!(hidden: false)
      end

      it "hides consultation tasks when changing to No" do
        expect(add_consultees_task).not_to be_hidden
        expect(send_emails_task).not_to be_hidden

        visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

        choose "No"
        click_button "Save and mark as complete"

        expect(add_consultees_task.reload).to be_hidden
        expect(send_emails_task.reload).to be_hidden
      end
    end
  end
end
