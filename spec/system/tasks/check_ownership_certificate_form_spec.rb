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

    it "displays the pending request details" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      choose "No"
      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Certificate type is wrong"
      click_button "Save and mark as complete"

      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_content("Ownership certificate change request created")
      expect(page).to have_content("Certificate type is wrong")
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
    let!(:validation_request) do
      create(:ownership_certificate_validation_request, :pending,
        planning_application:, reason: "Certificate type is wrong")
    end

    before do
      planning_application.update!(valid_ownership_certificate: false, ownership_certificate_checked: true)
      task.update!(status: :completed)
    end

    it "shows the form after deleting the request", js: true do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      accept_confirm do
        click_button "Delete request"
      end

      expect(page).to have_content("successfully deleted")
      expect(task.reload).to be_not_started
      expect { validation_request.reload }.to raise_error(ActiveRecord::RecordNotFound)

      # Form should now be visible again
      expect(page).to have_content("Is this declaration correct?")
      expect(page).to have_field("Yes")
      expect(page).to have_field("No")
    end
  end

  context "when updating the reason on an existing request via edit page" do
    let!(:validation_request) do
      create(:ownership_certificate_validation_request, :pending,
        planning_application:, reason: "Certificate type is wrong")
    end

    before do
      planning_application.update!(valid_ownership_certificate: false, ownership_certificate_checked: true)
      task.update!(status: :completed)
    end

    it "updates the existing request reason" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_link "Edit request"

      fill_in "Tell the applicant why the ownership certificate is incorrect", with: "Updated: certificate type should be C"
      click_button "Update request"

      expect(page).to have_content("successfully updated")
      expect(validation_request.reload.reason).to eq("Updated: certificate type should be C")
    end
  end

  context "when a pending validation request exists" do
    let!(:validation_request) do
      create(:ownership_certificate_validation_request, :pending,
        planning_application:, reason: "Certificate type is wrong")
    end

    before do
      planning_application.update!(valid_ownership_certificate: false, ownership_certificate_checked: true)
      task.update!(status: :completed)
    end

    it "shows the validation request details with 'created' heading" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_content("Ownership certificate change request created")
      expect(page).to have_content("Reason ownership certificate is invalid:")
      expect(page).to have_content("Certificate type is wrong")
    end

    it "shows the delete and edit links when application is not started" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_button("Delete request")
      expect(page).to have_link("Edit request")
    end

    it "allows deleting the validation request", js: true do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      accept_confirm do
        click_button "Delete request"
      end

      expect(page).to have_content("successfully deleted")
      expect(task.reload).to be_not_started
      expect { validation_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "allows editing the validation request reason" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_link "Edit request"

      expect(page).to have_content("Edit ownership certificate change request")
      expect(page).to have_field("Tell the applicant why the ownership certificate is incorrect", with: "Certificate type is wrong")

      fill_in "Tell the applicant why the ownership certificate is incorrect", with: "Updated reason: should be type C"
      click_button "Update request"

      expect(page).to have_content("successfully updated")
      expect(validation_request.reload.reason).to eq("Updated reason: should be type C")
    end
  end

  context "when application is invalidated with open validation request" do
    let!(:validation_request) do
      create(:ownership_certificate_validation_request, :open,
        planning_application:, reason: "Certificate type should be A")
    end

    before do
      planning_application.update!(
        valid_ownership_certificate: false,
        ownership_certificate_checked: true,
        status: "invalidated"
      )
      task.update!(status: :completed)
    end

    it "shows the validation request details with 'sent' heading" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_content("Ownership certificate change request sent")
      expect(page).to have_content("Reason ownership certificate is invalid:")
      expect(page).to have_content("Certificate type should be A")
    end

    it "shows the cancel link when application is invalidated" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      expect(page).to have_link("Cancel request")
    end

    it "allows cancelling the validation request" do
      within ".bops-sidebar" do
        click_link "Check ownership certificate"
      end

      click_link "Cancel request"

      expect(page).to have_content("Cancel validation request")
      expect(page).to have_content("Certificate type should be A")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_content("successfully cancelled")
      expect(validation_request.reload).to be_cancelled
    end
  end
end
