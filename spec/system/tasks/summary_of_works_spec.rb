# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summary of works task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/summary-of-works") }

  %i[planning_permission lawfulness_certificate prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, local_authority:)
      end

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}"
        click_link "Check and assess"
      end

      it "can have a summary added" do
        within :sidebar do
          click_link "Summary of works"
        end

        fill_in "tasks_summary_of_works_form[entry]", with: "test input"
        click_button "Save changes"

        expect(page).to have_selector("p", text: "test input")
        expect(page).to have_selector("textarea", text: "test input")
        expect(task).to be_in_progress

        click_button "Save and mark as complete"

        expect(page).to have_content("Summary of works was successfully saved")
        expect(task.reload).to be_completed
      end

      context "when there is an existing summary" do
        before do
          planning_application.assessment_details.create!(category: "summary_of_work", entry: "blah blah blah incorrect", user:)
          task.start!
        end

        it "can edit the summary" do
          within :sidebar do
            click_link "Summary of works"
          end

          expect(page).to have_selector("p", text: "blah blah blah incorrect")
          expect(page).to have_selector("textarea", text: "blah blah blah incorrect")
          expect(task).to be_in_progress

          fill_in "tasks_summary_of_works_form[entry]", with: "This is the correct result."
          click_button "Save and mark as complete"

          expect(page).to have_content("Summary of works was successfully saved")
          expect(page).to have_selector("p", text: "This is the correct result.")
          expect(task.reload).to be_completed
        end
      end
    end
  end
end
