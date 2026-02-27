# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add reporting details task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/add-reporting-details") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  %i[planning_permission prior_approval lawfulness_certificate].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :not_started, :with_reporting_type, local_authority:)
      end
      let(:reporting_type) { ReportingType.find_by!(code: planning_application.application_type.reporting_types.first) }

      it "shows the task in the sidebar with not started status" do
        expect(task.status).to eq("not_started")

        within :sidebar do
          expect(page).to have_link("Add reporting details")
        end
      end

      it "navigates to the task from the sidebar" do
        within :sidebar do
          click_link "Add reporting details"
        end

        expect(page).to have_content("Add reporting details")
        expect(page).to have_content("Select development type")
      end

      it "displays the form with reporting type options" do
        within :sidebar do
          click_link "Add reporting details"
        end

        expect(page).to have_content("Select development type")
        expect(page).to have_content(reporting_type.full_description)
        expect(page).to have_button("Save and mark as complete")
      end

      it "marks task as complete when selecting a reporting type" do
        expect(task).to be_not_started

        within :sidebar do
          click_link "Add reporting details"
        end

        choose reporting_type.full_description
        click_button "Save and mark as complete"

        expect(page).to have_content("Reporting details were successfully saved")
        expect(task.reload).to be_completed
        expect(planning_application.reload.reporting_type_id).to eq(reporting_type.id)
      end

      it "shows validation error when no reporting type is selected" do
        within :sidebar do
          click_link "Add reporting details"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Please select a development type for reporting")
        expect(task.reload).to be_not_started
      end

      it "allows editing after completion" do
        task.complete!
        planning_application.update!(reporting_type:)

        within :sidebar do
          click_link "Add reporting details"
        end

        click_button "Edit"

        expect(page).to have_checked_field(reporting_type.full_description)
        expect(page).to have_button("Save and mark as complete")
        expect(task.reload).to be_in_progress
      end

      it "allows selecting regulation 3 (LA owner and carrying out works)" do
        within :sidebar do
          click_link "Add reporting details"
        end

        choose reporting_type.full_description
        page.find("input[id$='regulation-true-field']", match: :first).click
        page.find("input[id$='regulation-3-true-field']", match: :first).click

        click_button "Save and mark as complete"

        expect(page).to have_content("Reporting details were successfully saved")
        expect(planning_application.reload.regulation_3).to be true
        expect(planning_application.regulation_4).to be false
      end

      it "allows selecting regulation 4 (LA owner but not carrying out works)" do
        within :sidebar do
          click_link "Add reporting details"
        end

        choose reporting_type.full_description
        page.find("input[id$='regulation-true-field']", match: :first).click
        page.find("input[id$='regulation-3-field']", match: :first).click

        click_button "Save and mark as complete"

        expect(page).to have_content("Reporting details were successfully saved")
        expect(planning_application.reload.regulation_3).to be false
        expect(planning_application.regulation_4).to be true
      end

      it "clears regulations when LA is not owner" do
        planning_application.update!(regulation_3: true)

        within :sidebar do
          click_link "Add reporting details"
        end

        choose reporting_type.full_description
        page.find("input[id$='-regulation-field']", match: :first).click

        click_button "Save and mark as complete"

        expect(page).to have_content("Reporting details were successfully saved")
        expect(planning_application.reload.regulation_3).to be false
        expect(planning_application.regulation_4).to be false
      end

      it "displays guidance when present" do
        within :sidebar do
          click_link "Add reporting details"
        end

        expect(page).to have_content("This is guidance for testing")
      end
    end
  end

  context "when no reporting types are configured for the application type" do
    let(:planning_application) { create(:planning_application, :planning_permission, :not_started, local_authority:) }

    before do
      ReportingType.destroy_all
    end

    it "shows message about no applicable reporting types" do
      within :sidebar do
        click_link "Add reporting details"
      end

      expect(page).to have_content("No applicable reporting types")
    end

    it "allows saving and completing without selecting a reporting type" do
      within :sidebar do
        click_link "Add reporting details"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Reporting details were successfully saved")
      expect(task.reload).to be_completed
    end
  end
end
