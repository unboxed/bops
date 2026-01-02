# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application consultation workflow", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  let(:planning_application) do
    create(:planning_application, :pre_application, :not_started, local_authority:)
  end

  before do
    sign_in(user)
  end

  describe "end-to-end consultation workflow" do
    it "completes all consultation tasks in sequence with correct status transitions and icons" do
      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).to have_css(".bops-sidebar")
      expect(page).to have_content("Consultation")

      determine_task = planning_application.case_record.find_task_by_slug_path!("consultees/determine-consultation-requirement")
      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      add_consultees_task = consultees_section.tasks.find_by(slug: "add-and-assign-consultees")
      send_emails_task = consultees_section.tasks.find_by(slug: "send-emails-to-consultees")
      view_responses_task = consultees_section.tasks.find_by(slug: "view-consultee-responses")

      expect(determine_task).to be_not_started
      expect(add_consultees_task).to be_hidden
      expect(send_emails_task).to be_hidden
      expect(view_responses_task).to be_hidden

      within ".bops-sidebar" do
        expect(page).to have_link("Determine consultation requirement")
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Determine consultation requirement") do
          expect(page).to have_css("svg[aria-label='Not started']")
        end
      end

      expect(page).to have_selector("h1", text: "Determine consultation requirement")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Determine consultation requirement")
        expect(page).to have_css("a[aria-current='page']", text: "Determine consultation requirement")
      end

      expect(page).to have_content("Is consultation required?")
      expect(page).to have_field("Yes")
      expect(page).to have_field("No")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
      expect(determine_task.reload).to be_completed
      expect(planning_application.reload.consultation_required).to be true

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Determine consultation requirement") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      expect(add_consultees_task.reload).not_to be_hidden
      expect(send_emails_task.reload).not_to be_hidden
      expect(view_responses_task.reload).not_to be_hidden

      within ".bops-sidebar" do
        expect(page).to have_link("Add and assign consultees")
        expect(page).to have_link("Send emails to consultees")
        expect(page).to have_link("View consultee responses")
      end

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Add and assign consultees") do
          expect(page).to have_css("svg[aria-label='Not started']")
        end
        within(".bops-sidebar__task", text: "Send emails to consultees") do
          expect(page).to have_css("svg[aria-label='Not started']")
        end
        within(".bops-sidebar__task", text: "View consultee responses") do
          expect(page).to have_css("svg[aria-label='Not started']")
        end
      end

      within ".bops-sidebar" do
        click_link "Add and assign consultees"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees")
      expect(page).to have_selector("h1", text: "Add and assign consultees")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Add and assign consultees")
      end

      expect(page).to have_content("Select constraints that require consultation")
      expect(page).to have_content("Assign consultees to each constraint")

      click_button "Save changes"

      expect(page).to have_content("Consultee assignments were successfully saved")
      expect(add_consultees_task.reload).to be_in_progress

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Add and assign consultees") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Consultee assignments were successfully saved")
      expect(add_consultees_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Add and assign consultees") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Send emails to consultees"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/send-emails-to-consultees")
      expect(page).to have_selector("h1", text: "Send emails to consultees")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Send emails to consultees")
      end

      send_emails_task.complete!

      within ".bops-sidebar" do
        click_link "View consultee responses"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/view-consultee-responses")
      expect(page).to have_selector("h1", text: "View consultee responses")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "View consultee responses")
      end

      expect(page).to have_content("No consultees have been added yet")

      click_button "Save and mark as complete"

      expect(page).to have_content("Consultee responses were successfully reviewed")
      expect(view_responses_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "View consultee responses") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      [determine_task, add_consultees_task, send_emails_task, view_responses_task].each do |task|
        expect(task.reload).to be_completed
      end
    end

    it "hides consultation tasks when consultation is not required" do
      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
      expect(planning_application.reload.consultation_required).to be false

      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      add_consultees_task = consultees_section.tasks.find_by(slug: "add-and-assign-consultees")
      send_emails_task = consultees_section.tasks.find_by(slug: "send-emails-to-consultees")
      view_responses_task = consultees_section.tasks.find_by(slug: "view-consultee-responses")

      expect(add_consultees_task.reload).to be_hidden
      expect(send_emails_task.reload).to be_hidden
      expect(view_responses_task.reload).to be_hidden

      within ".bops-sidebar" do
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end
    end

    it "navigates correctly between all consultation tasks" do
      planning_application.update!(consultation_required: true)
      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      consultees_section.tasks.update_all(hidden: false)

      tasks = [
        {name: "Determine consultation requirement", path: "determine-consultation-requirement"},
        {name: "Add and assign consultees", path: "add-and-assign-consultees"},
        {name: "Send emails to consultees", path: "send-emails-to-consultees"},
        {name: "View consultee responses", path: "view-consultee-responses"}
      ]

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      tasks.each do |task|
        within ".bops-sidebar" do
          click_link task[:name]
        end

        expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/#{task[:path]}")

        within ".bops-sidebar" do
          expect(page).to have_css(".bops-sidebar__task--active", text: task[:name])
          expect(page).to have_css("a[aria-current='page']", text: task[:name])
        end
      end
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current, consultation_required: true)
      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      consultees_section.tasks.update_all(hidden: false)

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")

      visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end

    it "shows warning when changing consultation requirement with existing consultees" do
      planning_application.update!(consultation_required: true)
      consultation = planning_application.consultation || planning_application.create_consultation!
      create(:consultee, consultation:, name: "Test Consultee")

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      expect(page).to have_selector(".govuk-warning-text", text: "Changing this answer to \"No\" will remove all consultees")
    end

    it "maintains sidebar scroll position across navigation", js: true do
      planning_application.update!(consultation_required: true)
      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      consultees_section.tasks.update_all(hidden: false)

      visit "/preapps/#{planning_application.reference}/consultees/determine-consultation-requirement"

      within ".bops-sidebar" do
        click_link "View consultee responses"
      end

      expect(page).to have_css(".bops-sidebar[data-controller='sidebar-scroll']")
    end
  end

  describe "consultee response handling" do
    let(:consultation) { planning_application.consultation || planning_application.create_consultation! }
    let!(:consultee_approved) do
      consultee = create(:consultee, :consulted, consultation:, name: "Thames Water", status: :responded)
      create(:consultee_response, consultee:, summary_tag: :approved, response: "No objection", email: consultee.email_address)
      consultee
    end
    let!(:consultee_objected) do
      consultee = create(:consultee, :consulted, consultation:, name: "Natural England", status: :responded)
      create(:consultee_response, consultee:, summary_tag: :objected, response: "We object", email: consultee.email_address)
      consultee
    end

    before do
      planning_application.update!(consultation_required: true)
      consultees_section = planning_application.case_record.find_task_by_slug_path!("consultees")
      consultees_section.tasks.update_all(hidden: false)
    end

    it "displays consultee responses with correct status tags" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("Response summary")
      expect(page).to have_content("Total consultees")

      expect(page).to have_link("All (2)")
      expect(page).to have_link("No objection (1)")
      expect(page).to have_link("Objection (1)")

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Thames Water") do
          expect(page).to have_content("No objection")
        end
        within(".consultee-panel", text: "Natural England") do
          expect(page).to have_content("Objection")
        end
      end
    end

    it "filters consultees by response type when clicking tabs" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      click_link "No objection (1)"

      within("#consultee-tab-approved") do
        expect(page).to have_content("Thames Water")
        expect(page).not_to have_content("Natural England")
      end

      click_link "Objection (1)"

      within("#consultee-tab-objected") do
        expect(page).to have_content("Natural England")
        expect(page).not_to have_content("Thames Water")
      end
    end
  end
end
