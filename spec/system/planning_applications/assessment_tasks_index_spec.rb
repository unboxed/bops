# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assessment tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  before do
    sign_in assessor
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("PLANNING_HISTORY_ENABLED", "false").and_return("true")
  end

  context "when I can assess the planning application" do
    let!(:planning_application) do
      create :planning_application, :in_assessment, local_authority: default_local_authority
    end

    it "displays the assessment tasks list" do
      visit planning_application_assessment_tasks_path(planning_application)

      within(".app-task-list") do
        within("#check-consistency-assessment-tasks") do
          expect(page).to have_content("Description, documents and proposal details")
          expect(page).to have_link("History")
        end

        within("#assess-against-legislation-tasks") do
          expect(page).to have_link("Add assessment area")
        end
      end
    end
  end

  context "when I cannot assess the planning application" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: default_local_authority
    end

    it "displays the assessment tasks list" do
      visit planning_application_assessment_tasks_path(planning_application)

      within(".app-task-list") do
        within("#check-consistency-assessment-tasks") do
          expect(page).to have_content("Description, documents and proposal details")
          expect(page).to have_link("History")
        end

        within("#assess-against-legislation-tasks") do
          expect(page).not_to have_link("Add assessment area")
          expect(page).to have_content("Add assessment area")
        end
      end
    end
  end
end
