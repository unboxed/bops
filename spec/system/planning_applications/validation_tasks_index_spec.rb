# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validation tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: default_local_authority
  end

  before do
    sign_in assessor
    visit planning_application_validation_tasks_path(planning_application)
  end

  context "when application is not started or invalidated" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: default_local_authority
    end

    it "displays the validation tasks list" do
      within(".app-task-list") do
        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).to have_link(
            "Add an other validation request",
            href: new_planning_application_other_change_validation_request_path(planning_application)
          )
        end

        within("#review-tasks") do
          expect(page).to have_content("Review")
          expect(page).to have_link(
            "Send validation decision",
            href: validation_decision_planning_application_path(planning_application)
          )
        end
      end

      expect(page).to have_link("Back", href: planning_application_path(planning_application))
    end
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create :planning_application, :in_assessment, local_authority: default_local_authority
    end

    it "displays the validation tasks list but no actions to create new requests can be taken" do
      within(".app-task-list") do
        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).not_to have_link("Add an other validation request")
        end

        within("#review-tasks") do
          expect(page).to have_content("Review")
          expect(page).to have_link(
            "Send validation decision",
            href: validation_decision_planning_application_path(planning_application)
          )
        end
      end

      expect(page).to have_link("Back", href: planning_application_path(planning_application))
    end
  end
end
