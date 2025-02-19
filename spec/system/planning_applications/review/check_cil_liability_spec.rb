# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking publicity" do
  let!(:local_authority) { create(:local_authority, :default, press_notice_email: "pressnotices@example.com") }

  let!(:assessor) do
    create(:user, :assessor, name: "Alice Smith", local_authority: local_authority)
  end

  let!(:reviewer) do
    create(:user, :reviewer, local_authority: local_authority)
  end

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: local_authority)
  end

  before do
    create(:recommendation, planning_application:)

    sign_in reviewer
  end

  context "when the validation officer has not filled in CIL liability" do
    before do
      planning_application.update(cil_liable: nil)
    end

    it "the reviewer can mark it as not needing confirmation" do
      visit "planning_applications/#{planning_application.id}/review/tasks"

      within "#review-cil-liability" do
        expect(page).to have_content "Not started"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer did not confirm whether the application is liable for CIL."

      within "#review-cil-liability" do
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "Review of CIL liability successfully updated"

      within "#review-cil-liability" do
        expect(page).to have_content "Completed"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer had not confirmed whether the application was liable"
      expect(page).to have_content "Reviewer marked application as not needing confirmation for CIL liability"
    end

    it "the reviewer can update it" do
      visit "planning_applications/#{planning_application.id}/review/tasks"

      within "#review-cil-liability" do
        expect(page).to have_content "Not started"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer did not confirm whether the application is liable for CIL."

      choose "Yes"

      within "#review-cil-liability" do
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "Review of CIL liability successfully updated"

      within "#review-cil-liability" do
        expect(page).to have_content "Completed"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer had not confirmed whether the application was liable"
      expect(page).to have_content "Reviewer marked application as liable for CIL"
    end
  end

  context "when the validation officer has filled in CIL liability" do
    before do
      planning_application.update(cil_liable: true)
    end

    it "the reviewer can mark it as correct" do
      visit "planning_applications/#{planning_application.id}/review/tasks"

      within "#review-cil-liability" do
        expect(page).to have_content "Not started"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer marked this application as liable for CIL"

      within "#review-cil-liability" do
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "Review of CIL liability successfully updated"

      within "#review-cil-liability" do
        expect(page).to have_content "Completed"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "Previously marked as liable by validation officer"
      expect(page).to have_content "Reviewer marked application as liable for CIL"
    end

    it "the reviewer can change it" do
      visit "planning_applications/#{planning_application.id}/review/tasks"

      within "#review-cil-liability" do
        expect(page).to have_content "Not started"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "The validation officer marked this application as liable for CIL"

      choose "No"

      within "#review-cil-liability" do
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "Review of CIL liability successfully updated"

      within "#review-cil-liability" do
        expect(page).to have_content "Completed"
      end

      click_button "Check Community Infrastructure Levy (CIL)"

      expect(page).to have_content "Previously marked as liable by validation officer"
      expect(page).to have_content "Reviewer marked application as not liable for CIL"
    end
  end

  context "when CIL liability feature is disabled" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, :pre_application, local_authority: local_authority)
    end

    it "does not have a section to review CIL" do
      visit "planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).not_to have_css("#review-cil-liability")
      expect(page).not_to have_content("Check Community Infrastructure Levy (CIL)")
    end
  end
end
