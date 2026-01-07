# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assign consultees", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, consultation_required: true) }
  let(:user) { create(:user, local_authority:) }
  let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
  let!(:constraint) { create(:planning_application_constraint, planning_application:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees/add-and-assign-consultees") }

  before do
    sign_in(user)
    task.update!(hidden: false)
  end

  describe "visiting the assign consultees page" do
    it "displays the page" do
      visit "/preapps/#{planning_application.reference}/consultees/new?constraint_id=#{constraint.id}&task_slug=#{task.full_slug}"

      expect(page).to have_content("Assign consultees")
    end

    it "shows the constraint name in the legend" do
      visit "/preapps/#{planning_application.reference}/consultees/new?constraint_id=#{constraint.id}&task_slug=#{task.full_slug}"

      expect(page).to have_content("Select consultees for #{constraint.type_code}")
    end

    it "has a back button linking to the task" do
      visit "/preapps/#{planning_application.reference}/consultees/new?constraint_id=#{constraint.id}&task_slug=#{task.full_slug}"

      expect(page).to have_link("Back", href: /add-and-assign-consultees/)
    end

    it "shows correct breadcrumb navigation" do
      visit "/preapps/#{planning_application.reference}/consultees/new?constraint_id=#{constraint.id}&task_slug=#{task.full_slug}"

      expect(page).to have_link("Home")
      expect(page).to have_link("Application")
      expect(page).to have_link("Add and assign consultees")
    end
  end

  describe "assigning consultees" do
    it "redirects back to task after submission" do
      visit "/preapps/#{planning_application.reference}/consultees/new?constraint_id=#{constraint.id}&task_slug=#{task.full_slug}"

      click_button "Assign consultees"

      expect(page).to have_content("Consultees were successfully assigned")
      expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees")
    end
  end
end
