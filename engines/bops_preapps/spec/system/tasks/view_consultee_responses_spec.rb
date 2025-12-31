# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View consultee responses task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, consultation_required: true) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees/view-consultee-responses") }
  let(:consultation) { planning_application.consultation || planning_application.create_consultation! }

  before do
    sign_in(user)
    task.update!(hidden: false)
  end

  describe "task status" do
    it "shows the task with not started status" do
      expect(task.status).to eq("not_started")
    end
  end

  describe "page navigation" do
    it "navigates to the task page" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("View consultee responses")
    end

    it "shows correct breadcrumb navigation" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_link("Home")
      expect(page).to have_link("Application")
      expect(page).not_to have_link("Consultation")
    end

    it "highlights the active task in the sidebar" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "View consultee responses")
        expect(page).to have_css("a[aria-current='page']", text: "View consultee responses")
      end
    end
  end

  describe "without consultees" do
    it "displays a message when no consultees exist" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("No consultees have been added yet")
    end

    it "still displays save buttons" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_button("Save and mark as complete")
      expect(page).to have_button("Save changes")
    end
  end

  describe "with consultees" do
    let!(:consultee_awaiting) do
      create(:consultee, :consulted, consultation:, name: "Environment Agency")
    end

    let!(:consultee_not_consulted) do
      create(:consultee, consultation:, name: "Historic England", status: :not_consulted)
    end

    it "displays the response summary panel" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("Response summary")
      expect(page).to have_content("Total consultees")
    end

    it "displays consultees in tabs" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_css(".govuk-tabs")
      expect(page).to have_link("All (2)")
    end

    it "displays consultee names" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("Environment Agency")
      expect(page).to have_content("Historic England")
    end

    it "displays consultee status" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("Awaiting response")
      expect(page).to have_content("Not consulted")
    end
  end

  describe "with consultee responses" do
    let!(:consultee_with_response) do
      consultee = create(:consultee, :consulted, consultation:, name: "Thames Water", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :approved,
        response: "We have no objection to this proposal.",
        email: consultee.email_address)
      consultee
    end

    let!(:consultee_with_objection) do
      consultee = create(:consultee, :consulted, consultation:, name: "Natural England", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :objected,
        response: "We object to this proposal due to ecological concerns.",
        email: consultee.email_address)
      consultee
    end

    let!(:consultee_amendments_needed) do
      consultee = create(:consultee, :consulted, consultation:, name: "Transport for London", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :amendments_needed,
        response: "Amendments are required to the access arrangements.",
        email: consultee.email_address)
      consultee
    end

    it "displays response tabs filtered by status" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_link("All (3)")
      expect(page).to have_link("No objection (1)")
      expect(page).to have_link("Objection (1)")
      expect(page).to have_link("Amendments needed (1)")
    end

    it "displays response snippets" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_content("We have no objection to this proposal.")
    end

    it "displays correct status tags for responses" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Thames Water") do
          expect(page).to have_content("No objection")
        end

        within(".consultee-panel", text: "Natural England") do
          expect(page).to have_content("Objection")
        end

        within(".consultee-panel", text: "Transport for London") do
          expect(page).to have_content("Amendments needed")
        end
      end
    end

    context "when clicking on a tab" do
      it "shows only objections in the objection tab" do
        visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

        click_link "Objection (1)"

        within("#consultee-tab-objected") do
          expect(page).to have_content("Natural England")
          expect(page).not_to have_content("Thames Water")
          expect(page).not_to have_content("Transport for London")
        end
      end

      it "shows only no objection responses in the no objection tab" do
        visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

        click_link "No objection (1)"

        within("#consultee-tab-approved") do
          expect(page).to have_content("Thames Water")
          expect(page).not_to have_content("Natural England")
        end
      end
    end
  end

  describe "task actions" do
    let!(:consultee) { create(:consultee, consultation:, name: "Test Consultee") }

    it "marks task as in progress when saving draft" do
      expect(task).to be_not_started

      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      click_button "Save changes"

      expect(page).to have_content("Consultee responses were successfully reviewed")
      expect(task.reload).to be_in_progress
    end

    it "marks task as complete when saving and marking as complete" do
      expect(task).to be_not_started

      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      click_button "Save and mark as complete"

      expect(page).to have_content("Consultee responses were successfully reviewed")
      expect(task.reload).to be_completed
    end

    it "stays on the task page after completion" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      click_button "Save and mark as complete"

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/view-consultee-responses")
    end

    it "displays both save buttons" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).to have_button("Save and mark as complete")
      expect(page).to have_button("Save changes")
    end

    it "does not regress a completed task when saving draft" do
      task.update!(status: :completed)

      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      click_button "Save changes"

      expect(page).to have_content("Consultee responses were successfully reviewed")
      expect(task.reload).to be_completed
    end
  end

  describe "with failed consultee" do
    let!(:failed_consultee) do
      create(:consultee, consultation:, name: "Failed Agency", status: :failed)
    end

    it "displays the failed status" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within(".consultee-panel", text: "Failed Agency") do
        expect(page).to have_content("Delivery failed")
      end
    end
  end

  describe "when application is determined" do
    before do
      planning_application.update!(status: "determined", determined_at: Time.current)
    end

    it "hides save buttons" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end
  end

  describe "task visibility" do
    before do
      task.update!(hidden: true)
    end

    it "is hidden until consultation is required" do
      expect(task).to be_hidden
    end
  end

  describe "response summary statistics" do
    let!(:responded_consultee) do
      consultee = create(:consultee, :consulted, consultation:, status: :responded)
      create(:consultee_response, consultee:, summary_tag: :approved, email: consultee.email_address)
      consultee
    end

    let!(:awaiting_consultee) { create(:consultee, :consulted, consultation:) }
    let!(:not_consulted_consultee) { create(:consultee, consultation:, status: :not_consulted) }

    it "displays correct summary counts" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within(".govuk-summary-card") do
        expect(page).to have_content("Total consultees")
        expect(page).to have_content("3")
        expect(page).to have_content("Responded")
        expect(page).to have_content("1")
        expect(page).to have_content("Awaiting response")
        expect(page).to have_content("1")
        expect(page).to have_content("Not consulted")
        expect(page).to have_content("1")
      end
    end
  end

  describe "multiple responses from same consultee" do
    let!(:consultee) do
      consultee = create(:consultee, :consulted, consultation:, name: "Multi Response Agency", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :amendments_needed,
        response: "Initial response with concerns.",
        received_at: 7.days.ago,
        email: consultee.email_address)
      create(:consultee_response,
        consultee:,
        summary_tag: :approved,
        response: "Updated response - concerns addressed.",
        received_at: 1.day.ago,
        email: consultee.email_address)
      consultee
    end

    it "shows the latest response status" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Multi Response Agency") do
          expect(page).to have_content("No objection")
        end
      end
    end
  end

  describe "consultee with role and organisation" do
    let!(:consultee_with_details) do
      create(:consultee, consultation:,
        name: "John Smith",
        role: "Planning Officer",
        organisation: "City Council")
    end

    it "displays role and organisation details" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within(".consultee-panel", text: "John Smith") do
        expect(page).to have_content("Planning Officer, City Council")
      end
    end
  end

  describe "internal and external consultees" do
    let!(:internal_consultee) { create(:consultee, :internal, consultation:, name: "Internal Team") }
    let!(:external_consultee) { create(:consultee, :external, consultation:, name: "External Agency") }

    it "displays internal/external type tags" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Internal Team") do
          expect(page).to have_content("Internal")
        end

        within(".consultee-panel", text: "External Agency") do
          expect(page).to have_content("External")
        end
      end
    end
  end

  describe "action links" do
    let!(:consultee_with_response) do
      consultee = create(:consultee, :consulted, consultation:, name: "Thames Water", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :approved,
        response: "We have no objection to this proposal.",
        email: consultee.email_address)
      consultee
    end

    let!(:consultee_without_response) do
      create(:consultee, :consulted, consultation:, name: "Environment Agency")
    end

    it "displays view all responses link for consultees with responses" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Thames Water") do
          expect(page).to have_link("View all responses (1)")
        end
      end
    end

    it "displays upload new response link for all consultees" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        within(".consultee-panel", text: "Thames Water") do
          expect(page).to have_link("Upload new response")
        end

        within(".consultee-panel", text: "Environment Agency") do
          expect(page).to have_link("Upload new response")
        end
      end
    end

    it "hides action links when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        expect(page).not_to have_link("View all responses")
        expect(page).not_to have_link("Upload new response")
      end
    end
  end

  describe "viewing consultee responses" do
    let!(:consultee) do
      consultee = create(:consultee, :consulted, consultation:, name: "Thames Water", email_address: "thames@example.com", status: :responded)
      create(:consultee_response,
        consultee:,
        summary_tag: :approved,
        response: "We have no objection to this proposal.",
        email: consultee.email_address,
        received_at: 2.days.ago)
      consultee
    end

    it "navigates to the view responses page" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        click_link "View all responses (1)"
      end

      expect(page).to have_content("View consultee responses")
      expect(page).to have_content("Thames Water")
    end

    it "displays consultee summary on the view responses page" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      expect(page).to have_content("Thames Water")
      expect(page).to have_content("thames@example.com")
    end

    it "displays the response list" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      expect(page).to have_content("We have no objection to this proposal.")
    end

    it "has a back button that returns to the task" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      click_link "Back"

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/view-consultee-responses")
    end

    it "has an upload new response button" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      expect(page).to have_link("Upload new response")
    end

    it "maintains the task sidebar" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      expect(page).to have_css(".bops-sidebar")
    end
  end

  describe "uploading a new response" do
    let!(:consultee) do
      create(:consultee, :consulted, consultation:, name: "Thames Water", email_address: "thames@example.com")
    end

    it "navigates to the upload response page" do
      visit "/preapps/#{planning_application.reference}/consultees/view-consultee-responses"

      within("#consultee-tab-all") do
        click_link "Upload new response"
      end

      expect(page).to have_content("Upload consultee response")
      expect(page).to have_content("Add a new response")
    end

    it "displays the response form fields" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      expect(page).to have_field("Name")
      expect(page).to have_field("Email")
      expect(page).to have_content("Response received on")
      expect(page).to have_content("Is the response")
      expect(page).to have_field("Response")
      expect(page).to have_field("Redacted response")
    end

    it "maintains the task sidebar" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      expect(page).to have_css(".bops-sidebar")
    end

    it "has a back button that returns to the task" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      click_link "Back"

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/view-consultee-responses")
    end

    it "successfully creates a response and redirects to the task" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      fill_in "Name", with: "John Doe"
      fill_in "Email", with: "john@example.com"
      fill_in "consultee_response[received_at(3i)]", with: "15"
      fill_in "consultee_response[received_at(2i)]", with: "12"
      fill_in "consultee_response[received_at(1i)]", with: "2024"
      choose "No objection"
      fill_in "Response", with: "We have reviewed the proposal and have no objection."
      fill_in "Redacted response", with: "No objection to the proposal."

      click_button "Save response"

      expect(page).to have_content("Response was successfully uploaded")
      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/view-consultee-responses")
      expect(consultee.responses.count).to eq(1)
    end

    it "shows validation errors when form is invalid" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      click_button "Save response"

      expect(page).to have_content("There is a problem")
    end
  end

  describe "breadcrumb navigation on response pages" do
    let!(:consultee) do
      create(:consultee, :consulted, consultation:, name: "Thames Water")
    end

    it "shows correct breadcrumbs on view responses page" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses?task_slug=consultees/view-consultee-responses"

      expect(page).to have_link("Home")
      expect(page).to have_link("Application")
      expect(page).to have_link("Consultation")
      expect(page).to have_link("View consultee responses")
    end

    it "shows correct breadcrumbs on upload response page" do
      visit "/preapps/#{planning_application.reference}/consultees/#{consultee.id}/responses/new?task_slug=consultees/view-consultee-responses"

      expect(page).to have_link("Home")
      expect(page).to have_link("Application")
      expect(page).to have_link("Consultation")
      expect(page).to have_link("View consultee responses")
    end
  end
end
