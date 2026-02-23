# frozen_string_literal: true

RSpec.shared_examples "review validation requests task" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:, name: "Alice Smith") }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/review/review-validation-requests") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  context "with an approved description change validation request" do
    let!(:description_change_request) do
      create(:description_change_validation_request,
        planning_application:,
        approved: true,
        state: "closed")
    end

    it "returns to the review validation requests task after marking description as complete" do
      within :sidebar do
        click_link "Review validation requests"
      end

      expect(page).to have_selector("h1", text: "Review validation requests")

      within "table tbody tr:nth-of-type(1)" do
        click_link "View and update"
      end

      expect(page).to have_content("Description change request")
      expect(page).to have_content("Approved on")

      click_button "Save and mark as complete"

      expect(page).to have_content("Description check was successfully saved")
      expect(page).to have_current_path(%r{/check-and-validate/review/review-validation-requests})
    end
  end

  context "with a pending fee change validation request" do
    let!(:fee_change_request) do
      create(:fee_change_validation_request,
        :pending,
        planning_application:,
        reason: "Fee is incorrect",
        suggestion: "Please pay the correct fee")
    end

    it "returns to the review validation requests task after editing the request" do
      within :sidebar do
        click_link "Review validation requests"
      end

      expect(page).to have_selector("h1", text: "Review validation requests")

      within "table tbody tr:nth-of-type(1)" do
        click_link "View and update"
      end

      expect(page).to have_content("Fee change request sent")

      click_link "Edit request"

      fill_in "Tell the applicant why the fee is incorrect", with: "Updated fee reason"
      fill_in "Tell the applicant what they need to do", with: "Updated suggestion"
      click_button "Update request"

      expect(page).to have_content("Fee change request successfully updated")
      expect(page).to have_current_path(%r{/check-and-validate/review/review-validation-requests})
    end
  end
end
