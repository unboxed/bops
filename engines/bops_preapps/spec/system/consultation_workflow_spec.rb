# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application consultation workflow", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  let(:planning_application) do
    create(:planning_application, :pre_application, :not_started, local_authority:)
  end

  let(:reference) { planning_application.reference }

  before do
    sign_in(user)
  end

  describe "end-to-end consultation workflow" do
    it "completes all consultation tasks in sequence with correct status transitions and icons" do
      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      expect(page).to have_selector(:sidebar)
      expect(page).to have_content("Consultation")

      expect(task("Determine consultation requirement")).to be_not_started
      expect(task("Add and assign consultees")).to be_hidden
      expect(task("Send emails to consultees")).to be_hidden
      expect(task("View consultee responses")).to be_hidden

      within :sidebar do
        expect(page).to have_link("Determine consultation requirement")
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end

      expect(page).to have_selector(:not_started_sidebar_task, "Determine consultation requirement")
      expect(page).to have_selector("h1", text: "Determine consultation requirement")
      expect(page).to have_selector(:active_sidebar_task, "Determine consultation requirement")

      expect(page).to have_content("Is consultation required?")
      expect(page).to have_field("Yes")
      expect(page).to have_field("No")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
      expect(task("Determine consultation requirement").reload).to be_completed
      expect(planning_application.reload.consultation_required).to be true
      expect(page).to have_selector(:completed_sidebar_task, "Determine consultation requirement")

      expect(task("Add and assign consultees").reload).not_to be_hidden
      expect(task("Send emails to consultees").reload).not_to be_hidden
      expect(task("View consultee responses").reload).not_to be_hidden

      within :sidebar do
        expect(page).to have_link("Add and assign consultees")
        expect(page).to have_link("Send emails to consultees")
        expect(page).to have_link("View consultee responses")
      end

      expect(page).to have_selector(:not_started_sidebar_task, "Add and assign consultees")
      expect(page).to have_selector(:not_started_sidebar_task, "Send emails to consultees")
      expect(page).to have_selector(:not_started_sidebar_task, "View consultee responses")

      within :sidebar do
        click_link "Add and assign consultees"
      end

      expect(page).to have_current_path("/preapps/#{reference}/consultees/add-and-assign-consultees")
      expect(page).to have_selector("h1", text: "Add and assign consultees")
      expect(page).to have_selector(:active_sidebar_task, "Add and assign consultees")

      expect(page).to have_content("Select constraints that require consultation")
      expect(page).to have_content("Assign consultees to each constraint")

      click_button "Save changes"

      expect(page).to have_content("Consultee assignments were successfully saved")
      expect(task("Add and assign consultees").reload).to be_in_progress
      expect(page).to have_selector(:in_progress_sidebar_task, "Add and assign consultees")

      click_button "Save and mark as complete"

      expect(page).to have_content("Consultee assignments were successfully saved")
      expect(task("Add and assign consultees").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Add and assign consultees")

      within :sidebar do
        click_link "Send emails to consultees"
      end

      expect(page).to have_current_path("/preapps/#{reference}/consultees/send-emails-to-consultees")
      expect(page).to have_selector("h1", text: "Send emails to consultees")
      expect(page).to have_selector(:active_sidebar_task, "Send emails to consultees")

      task("Send emails to consultees").complete!

      within :sidebar do
        click_link "View consultee responses"
      end

      expect(page).to have_current_path("/preapps/#{reference}/consultees/view-consultee-responses")
      expect(page).to have_selector("h1", text: "View consultee responses")
      expect(page).to have_selector(:active_sidebar_task, "View consultee responses")

      expect(page).to have_content("No consultees have been added yet")

      click_button "Save and mark as complete"

      expect(page).to have_content("Consultee responses were successfully reviewed")
      expect(task("View consultee responses").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "View consultee responses")

      [
        task("Determine consultation requirement"),
        task("Add and assign consultees"),
        task("Send emails to consultees"),
        task("View consultee responses")
      ].each do |t|
        expect(t.reload).to be_completed
      end
    end

    it "hides consultation tasks when consultation is not required" do
      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")
      expect(planning_application.reload.consultation_required).to be false

      expect(task("Add and assign consultees").reload).to be_hidden
      expect(task("Send emails to consultees").reload).to be_hidden
      expect(task("View consultee responses").reload).to be_hidden

      within :sidebar do
        expect(page).not_to have_link("Add and assign consultees")
        expect(page).not_to have_link("Send emails to consultees")
        expect(page).not_to have_link("View consultee responses")
      end
    end

    it "navigates correctly between all consultation tasks" do
      planning_application.update!(consultation_required: true)
      consultees_section.tasks.update_all(hidden: false)

      tasks = [
        {name: "Determine consultation requirement", path: "determine-consultation-requirement"},
        {name: "Add and assign consultees", path: "add-and-assign-consultees"},
        {name: "Send emails to consultees", path: "send-emails-to-consultees"},
        {name: "View consultee responses", path: "view-consultee-responses"}
      ]

      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      tasks.each do |t|
        within :sidebar do
          click_link t[:name]
        end

        expect(page).to have_current_path("/preapps/#{reference}/consultees/#{t[:path]}")
        expect(page).to have_selector(:active_sidebar_task, t[:name])
      end
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current, consultation_required: true)
      consultees_section.tasks.update_all(hidden: false)

      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")

      visit "/preapps/#{reference}/consultees/add-and-assign-consultees"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end

    it "shows warning when changing consultation requirement with existing consultees" do
      planning_application.update!(consultation_required: true)
      consultation = planning_application.consultation || planning_application.create_consultation!
      create(:consultee, consultation:, name: "Test Consultee")

      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      expect(page).to have_selector(".govuk-warning-text", text: "Changing this answer to \"No\" will remove all consultees")
    end

    it "maintains sidebar scroll position across navigation", js: true do
      planning_application.update!(consultation_required: true)
      consultees_section.tasks.update_all(hidden: false)

      visit "/preapps/#{reference}/consultees/determine-consultation-requirement"

      within :sidebar do
        click_link "View consultee responses"
      end

      expect(page).to have_css("nav.bops-sidebar[data-controller='sidebar-scroll']")

      initial_scroll = page.evaluate_script("document.querySelector('nav.bops-sidebar').scrollTop")

      within :sidebar do
        click_link "Determine consultation requirement"
      end

      final_scroll = page.evaluate_script("document.querySelector('nav.bops-sidebar').scrollTop")
      expect(final_scroll).to eq(initial_scroll)
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
      consultees_section.tasks.update_all(hidden: false)
    end

    it "displays consultee responses with correct status tags" do
      visit "/preapps/#{reference}/consultees/view-consultee-responses"

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
      visit "/preapps/#{reference}/consultees/view-consultee-responses"

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
