# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check and request documents task", type: :system do
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

  it_behaves_like "check and request documents task", :pre_application

  describe "cancelling a replacement document request" do
    let(:local_authority) { create(:local_authority, :default) }
    let(:user) { create(:user, local_authority:) }
    let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-tag-and-confirm-documents/check-and-request-documents") }
    let(:planning_application) { create(:planning_application, :pre_application, :invalidated, local_authority:) }
    let!(:document) { create(:document, :with_tags, planning_application:) }
    let!(:replacement_request) do
      create(:replacement_document_validation_request, :open,
        planning_application:,
        old_document: document,
        user:)
    end

    before do
      sign_in(user)
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "can cancel the replacement document request from the task page" do
      within :sidebar do
        click_link "Check and request documents"
      end

      within "#all" do
        click_link "Cancel replacement request"
      end

      expect(page).to have_content("Cancel validation request")

      expect {
        fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
        click_button "Confirm cancellation"
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_content("Document request successfully cancelled")
      expect(replacement_request.reload).to be_cancelled
    end
  end
end
