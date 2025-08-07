# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check report details", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:case_record) { build(:case_record, local_authority:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in user
    visit "/cases/#{enforcement.case_record.id}/check-breach-report"
  end

  context "when checking report" do
    before do
      click_link "Check report details"
    end

    it "shows the relevant report details" do
      expect(page).to have_content("Check report details")
      expect(page).to have_content("Quick close")
      expect(page).to have_content("Is this case urgent?")
    end

    it "allows me to edit the site description" do
      click_link "Edit description"
      expect(page).to have_selector("h1", text: "Edit description")
      expect(page).to have_content("Existing description")

      expect(page).to have_content("Enter an amended description")
      fill_in "Enter an amended description", with: "This description has been updated to reflect amendments to the submission."

      click_button "Save"

      expect(page).to have_content("This description has been updated to reflect amendments to the submission.")
    end

    it "allows me to mark a case as urgent" do
      expect(page).not_to have_selector(".govuk_tag", text: "urgent")
      check "Select here if the case is urgent"

      click_button "Save and mark as complete"
      expect(page).to have_content("Report details successfully checked")
      expect(page).to have_content("urgent")

      within(".govuk-task-list") do
        expect(page).to have_content("Completed")
      end
    end
  end
end
