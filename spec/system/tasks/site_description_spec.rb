# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site description task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/site-description") }

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

      it "can have a site description added" do
        within :sidebar do
          click_link "Site description"
        end

        fill_in "tasks_site_description_form[entry]", with: "test input"
        click_button "Save changes"

        expect(page).to have_selector("textarea", text: "test input")
        expect(task).to be_in_progress

        click_button "Save and mark as complete"

        expect(page).to have_content("Site description successfully saved")
        expect(task.reload).to be_completed
        expect(planning_application.assessment_details.where(category: "site_description").length).to eq(1)
      end

      context "when there is an existing description" do
        before do
          planning_application.assessment_details.create!(category: "site_description", entry: "Incorrect site description that needs changing.", user:)
          task.start!
        end

        it "can edit the summary" do
          within :sidebar do
            click_link "Site description"
          end

          expect(page).to have_selector("textarea", text: "Incorrect site description that needs changing.")
          expect(task).to be_in_progress

          fill_in "tasks_site_description_form[entry]", with: "This is the correct result."
          click_button "Save and mark as complete"

          expect(page).to have_content("Site description successfully saved")
          expect(page).to have_content("This is the correct result.")
          expect(task.reload).to be_completed
        end
      end
    end
  end
end
