# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add and assign consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  %i[prior_approval planning_permission].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, :published, local_authority:)
      end
      let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
      let(:slug) { "consultees-neighbours-and-publicity/consultees/add-and-assign-consultees" }
      let(:task) { planning_application.case_record.find_task_by_slug_path!(slug) }

      before do
        sign_in(user)
      end

      it "displays the add and assign consultees page" do
        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        expect(page).to have_content("Add and assign consultees")
        expect(page).to have_content("Select constraints that require consultation")
        expect(page).to have_content("Assign consultees")
      end

      it "displays planning constraints for selection" do
        create(:planning_application_constraint, planning_application:)

        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        expect(page).to have_css(".consultee-selection__list")
      end

      it "stays on the task page after toggling a constraint checkbox" do
        constraint = create(:planning_application_constraint, planning_application:)
        task_url = "/planning_applications/#{planning_application.reference}/#{slug}"

        visit task_url

        check constraint.type_code

        expect(page).to have_current_path(task_url)
        expect(page).to have_content("Add and assign consultees")
      end

      it "stays on the task page after removing an assigned consultee" do
        constraint = create(:planning_application_constraint, planning_application:, consultation_required: true)
        consultee = create(:consultee, consultation:, name: "Environment Agency")
        PlanningApplicationConstraintConsultee.create!(planning_application_constraint: constraint, consultee: consultee)

        task_url = "/planning_applications/#{planning_application.reference}/#{slug}"
        visit task_url

        click_link "Remove"

        expect(page).to have_current_path(task_url)
        expect(page).to have_content("Add and assign consultees")
      end

      it "links to assign consultee page with task context" do
        create(:planning_application_constraint, planning_application:, consultation_required: true)

        task_url = "/planning_applications/#{planning_application.reference}/#{slug}"
        visit task_url

        click_link "Assign consultee"

        expect(page).to have_content("Assign consultees")
        click_link "Back"

        expect(page).to have_current_path(task_url)
      end

      it "saves as draft and marks task in progress" do
        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        click_button "Save changes"

        expect(page).to have_content("Consultee assignments draft was saved")
        expect(task.reload).to be_in_progress
      end

      it "saves and marks the task as complete" do
        visit "/planning_applications/#{planning_application.reference}/#{slug}"

        click_button "Save and mark as complete"

        expect(page).to have_content("Consultees have been successfully assigned")
        expect(task.reload).to be_completed
      end
    end
  end
end
