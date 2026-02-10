# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check legislative requirements task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-legislative-requirements") }

  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and validate"
  end

  context "when the application type is a lawfulness certificate" do
    let(:planning_application) { create(:planning_application, :lawfulness_certificate, :not_started, local_authority:) }

    it "highlights the active task in the sidebar" do
      within ".bops-sidebar" do
        click_link "Check legislative requirements"
      end

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check legislative requirements")
      end
    end

    it "displays the legislation title" do
      within ".bops-sidebar" do
        click_link "Check legislative requirements"
      end

      expect(page).to have_content(planning_application.application_type.legislation_title)
    end

    it "displays the proposal details" do
      within ".bops-sidebar" do
        click_link "Check legislative requirements"
      end

      expect(page).to have_element("span", text: "Proposal details")
    end

    context "when marking legislative requirements as checked" do
      it "completes the task" do
        within ".bops-sidebar" do
          click_link "Check legislative requirements"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Successfully checked legislative requirements")
        expect(task.reload).to be_completed
      end
    end

    context "when the task is already completed" do
      before do
        task.update!(status: :completed)
      end

      it "shows the Edit button" do
        within ".bops-sidebar" do
          click_link "Check legislative requirements"
        end

        expect(page).to have_button("Edit")
      end

      it "allows editing the task" do
        within ".bops-sidebar" do
          click_link "Check legislative requirements"
        end

        click_button "Edit"

        expect(task.reload).to be_in_progress
        expect(page).to have_button("Save and mark as complete")
      end
    end
  end

  context "when the application type is a prior approval" do
    let(:planning_application) { create(:planning_application, :prior_approval, :not_started, local_authority:) }

    it "displays the legislation information" do
      within ".bops-sidebar" do
        click_link "Check legislative requirements"
      end

      expect(page).to have_content(planning_application.application_type.legislation_description)
      expect(page).to have_link(
        planning_application.application_type.legislation_title,
        href: planning_application.application_type.legislation_link
      )
    end

    context "when marking legislative requirements as checked" do
      it "completes the task" do
        within ".bops-sidebar" do
          click_link "Check legislative requirements"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Successfully checked legislative requirements")
        expect(task.reload).to be_completed
      end
    end

    context "when the task is already completed" do
      before do
        task.update!(status: :completed)
      end

      it "allows editing the task" do
        within ".bops-sidebar" do
          click_link "Check legislative requirements"
        end

        click_button "Edit"

        expect(task.reload).to be_in_progress
        expect(page).to have_button("Save and mark as complete")
      end
    end
  end
end
