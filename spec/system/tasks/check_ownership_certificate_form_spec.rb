# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check ownership certificate task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :planning_permission, :not_started, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/confirm-application-requirements/check-ownership-certificate") }

  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and validate"
  end

  it "highlights the active task in the sidebar" do
    within ".bops-sidebar" do
      click_link "Check ownership certificate"
    end

    within ".bops-sidebar" do
      expect(page).to have_css(".bops-sidebar__task--active", text: "Check ownership certificate")
    end
  end

  context "when there is no ownership certificate" do
    it "displays 'Not specified' for certificate type" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-validate/confirm-application-requirements/check-ownership-certificate")
      expect(page).to have_content("Not specified")
    end
  end

  context "when there is an ownership certificate with land owners" do
    let!(:ownership_certificate) { create(:ownership_certificate, planning_application:, certificate_type: "b") }
    let!(:land_owner) { create(:land_owner, ownership_certificate:, name: "Lauren James", address_1: "123 street", postcode: "MA1 123", notice_given: true, notice_given_at: Time.zone.local(2024, 6, 15)) }

    it "displays the certificate type and owner details" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_content("B")
      expect(page).to have_content("Lauren James")
      expect(page).to have_content("123 street")
      expect(page).to have_content("Yes")
    end
  end

  context "when marking the certificate as valid" do
    it "completes the task" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.valid_ownership_certificate).to be true
      expect(planning_application.ownership_certificate_checked).to be true
    end
  end

  context "when marking the certificate as invalid" do
    it "completes the task and creates a validation request" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      choose "No"
      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Certificate type should be A, not B"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.valid_ownership_certificate).to be false
      expect(planning_application.ownership_certificate_checked).to be true

      request = planning_application.ownership_certificate_validation_requests.last
      expect(request.reason).to eq("Certificate type should be A, not B")
    end

    it "displays a message about the pending request" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      choose "No"
      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Certificate type is wrong"
      click_button "Save and mark as complete"

      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_content("Request for more information about ownership certificate will be sent once application has been made invalid")
    end
  end

  context "when submitting without selecting an option" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Select whether the ownership certificate is valid.")
      expect(task.reload).not_to be_completed
    end
  end

  context "when selecting No without providing a reason" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_content("Explain why the ownership certificate is invalid")
      expect(task.reload).not_to be_completed
    end
  end

  context "when changing from invalid to valid" do
    before do
      planning_application.update!(valid_ownership_certificate: false, ownership_certificate_checked: true)
      create(:ownership_certificate_validation_request, :pending,
        planning_application:, reason: "Certificate type is wrong")
      task.update!(status: :completed)
    end

    it "destroys the existing validation request" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_button "Edit"

      choose "Yes"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.valid_ownership_certificate).to be true
      expect(planning_application.ownership_certificate_validation_requests.open_or_pending).to be_empty
    end
  end

  context "when updating the reason on an existing request" do
    before do
      planning_application.update!(valid_ownership_certificate: false, ownership_certificate_checked: true)
      create(:ownership_certificate_validation_request, :pending,
        planning_application:, reason: "Certificate type is wrong")
      task.update!(status: :completed)
    end

    it "updates the existing request instead of creating a new one" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_button "Edit"

      choose "No"
      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Updated: certificate type should be C"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.ownership_certificate_validation_requests.count).to eq(1)

      request = planning_application.ownership_certificate_validation_requests.open_or_pending.first
      expect(request.reason).to eq("Updated: certificate type should be C")
    end
  end
end
