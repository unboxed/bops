# frozen_string_literal: true

RSpec.shared_examples "check and request documents task" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-tag-and-confirm-documents/check-and-request-documents") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "displays the task in the sidebar and shows the page" do
    within :sidebar do
      click_link "Check and request documents"
    end

    expect(page).to have_content("Check for missing documents")
    expect(page).to have_content("Check all necessary documents have been provided")
  end

  it "can complete the task" do
    within :sidebar do
      click_link "Check and request documents"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Documents check saved")
    expect(task.reload).to be_completed
  end

  it "can edit a completed task" do
    within :sidebar do
      click_link "Check and request documents"
    end

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    click_button "Edit"
    expect(task.reload).to be_in_progress

    expect(page).to have_button("Save and mark as complete")
  end

  context "with documents" do
    let!(:document) { create(:document, :with_tags, planning_application:) }

    it "displays documents in tabs" do
      within :sidebar do
        click_link "Check and request documents"
      end

      expect(page).to have_content("All")
      expect(page).to have_content("Drawings")
      expect(page).to have_content("Supporting documents")
      expect(page).to have_content("Evidence")
    end
  end

  context "with a document checklist configured" do
    before do
      local_authority.update!(document_checklist: "https://example.com/checklist")
    end

    it "displays a link to the checklist" do
      within :sidebar do
        click_link "Check and request documents"
      end

      expect(page).to have_link("Checklist for #{planning_application.application_type.name.humanize.downcase}")
    end
  end

  context "with an open additional document validation request" do
    let!(:additional_document_request) do
      create(
        :additional_document_validation_request,
        planning_application:,
        user:,
        state: "open",
        document_request_type: "Floor plan",
        reason: "Missing floor plan"
      )
    end

    it "displays the pending request in the table" do
      within :sidebar do
        click_link "Check and request documents"
      end

      expect(page).to have_content("Floor plan")
      expect(page).to have_content("Missing floor plan")
    end

    it "sets documents_missing to true when completing with pending requests" do
      within :sidebar do
        click_link "Check and request documents"
      end

      click_button "Save and mark as complete"

      expect(planning_application.reload.documents_missing).to be true
    end
  end

  context "without any pending additional document validation requests" do
    it "sets documents_missing to false when completing" do
      within :sidebar do
        click_link "Check and request documents"
      end

      click_button "Save and mark as complete"

      expect(planning_application.reload.documents_missing).to be false
    end
  end

  it "displays a link to add a request for a missing document" do
    within :sidebar do
      click_link "Check and request documents"
    end

    expect(page).to have_link("Add a request for a missing document")
  end

  context "when application is invalidated" do
    let(:planning_application) { create(:planning_application, application_type, :invalidated, local_authority:, documents_missing: true) }

    let!(:additional_document_request) do
      create(
        :additional_document_validation_request, :open,
        planning_application:,
        user:,
        document_request_type: "Floor plan",
        reason: "Missing floor plan"
      )
    end

    it "displays cancel link for the request" do
      within :sidebar do
        click_link "Check and request documents"
      end

      expect(page).to have_link("Cancel request")
      expect(page).not_to have_link("Edit request")
      expect(page).not_to have_link("Delete request")
    end

    it "can cancel a request" do
      within :sidebar do
        click_link "Check and request documents"
      end

      click_link "Cancel request"

      expect(page).to have_content("Cancel validation request")
      expect(page).to have_content("Additional document validation request")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_content("Document request successfully cancelled")
      expect(additional_document_request.reload).to be_cancelled
      expect(task.reload).to be_not_started
    end

    it "shows validation error when cancel reason is blank" do
      within :sidebar do
        click_link "Check and request documents"
      end

      click_link "Cancel request"
      click_button "Confirm cancellation"

      expect(page).to have_content("Enter Cancel reason")
    end
  end

  context "when application is not started with a pending request" do
    let!(:additional_document_request) do
      create(
        :additional_document_validation_request, :pending,
        planning_application:,
        user:,
        document_request_type: "Floor plan",
        reason: "Missing floor plan"
      )
    end

    it "does not show cancel link but shows edit and delete" do
      within :sidebar do
        click_link "Check and request documents"
      end

      expect(page).not_to have_link("Cancel request")
      expect(page).to have_link("Edit request")
      expect(page).to have_link("Delete request")
    end
  end
end
