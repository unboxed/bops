# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reporting validation task" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reporting_type) { create(:reporting_type, :ldc) }

  let!(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  context "when application is not started" do
    it "I can select the development type for reporting" do
      click_link "Add reporting details"
      choose "Q26 – Certificates of lawful development"

      expect(page).to have_content("Includes both existing & proposed applications")

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Reporting details were successfully saved")
      end
    end

    it "shows errors when a development type for reporting is not selected" do
      click_link "Add reporting details"
      click_button "Save and mark as complete"

      expect(page).to have_content "Please select a development type for reporting"
    end

    context "when no reporting type for the application type exists" do
      let!(:planning_application) do
        create(:planning_application, :planning_permission, :not_started, local_authority: default_local_authority)
      end

      it "I can save and mark as complete" do
        click_link "Add reporting details"
        expect(page).to have_content("No applicable reporting types. Please configure them for the application type if they are required.")
        click_button "Save and mark as complete"

        expect(page).to have_content "Reporting details were successfully saved"
      end
    end

    it "shows errors when Yes or No is not selected for whether the local authority is carrying out the works proposed" do
      click_link "Add reporting details"
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-true-field"]').click
      click_button "Save and mark as complete"

      expect(page).to have_content "Please select a development type for reporting"
    end

    it "I can report whether regulation 3 applies" do
      click_link "Add reporting details"
      choose "Q26 – Certificates of lawful development"

      expect(page).to have_content("Includes both existing & proposed applications")

      # Radios within radios makes finding 'yes' complicated
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-true-field"]').click
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-3-true-field"]').click

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Reporting details were successfully saved")
      end

      expect(planning_application.reload.regulation_3).to be true
      expect(planning_application.reload.regulation_4).to be false
    end

    it "I can report whether regulation 4 applies" do
      click_link "Add reporting details"
      choose "Q26 – Certificates of lawful development"

      expect(page).to have_content("Includes both existing & proposed applications")

      # Radios within radios makes finding 'yes' complicated
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-true-field"]').click
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-3-field"]').click

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Reporting details were successfully saved")
      end

      expect(planning_application.reload.regulation_3).to be false
      expect(planning_application.reload.regulation_4).to be true
    end

    it "I can edit the regulations" do
      click_link "Add reporting details"

      choose "Q26 – Certificates of lawful development"

      expect(page).to have_content("Includes both existing & proposed applications")

      # Radios within radios makes finding 'yes' complicated
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-true-field"]').click
      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-3-field"]').click

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Reporting details were successfully saved")
      end

      expect(page).not_to have_content "Save and mark as complete"
      click_button "Edit"

      page.find(:xpath, '//*[@id="tasks-add-reporting-details-form-regulation-field"]').click

      click_button "Save and mark as complete"

      expect(planning_application.reload.regulation_3).to be false
      expect(planning_application.reload.regulation_4).to be false
    end
  end
end
