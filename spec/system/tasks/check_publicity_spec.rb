# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/check-publicity") }

  %i[planning_permission prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, local_authority:)
      end

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      end

      it "allows the task to be marked as complete" do
        within :sidebar do
          click_link "Check publicity"
        end

        click_button "Save and mark as complete"

        expect(task).to be_completed
      end
    end
  end
end
