# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page", type: :system do
  let(:reviewer) { create :user, :reviewer, local_authority: @default_local_authority }
  let(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  context "as a reviewer" do
    before do
      sign_in reviewer
    end

    it "makes valid task list for not_started" do
      planning_application = create(:planning_application, :not_started, local_authority: @default_local_authority)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: false)
      task_item_exists("Assess Proposal", linked: false, completed: false)
      task_item_exists("Submit Recommendation", linked: false, completed: false)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it has been validated but no proposal has been made" do
      planning_application = create(:planning_application, local_authority: @default_local_authority)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: true, completed: false)
      task_item_exists("Submit Recommendation", linked: false, completed: false)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it in assessment and a proposal has been created" do
      planning_application = create(:planning_application, local_authority: @default_local_authority)
      create(:recommendation, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: true, completed: true)
      task_item_exists("Submit Recommendation", linked: true, completed: false)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it is awaiting determination" do
      planning_application = create(:planning_application, :awaiting_determination, local_authority: @default_local_authority)
      create(:recommendation, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: false, completed: true)
      task_item_exists("Submit Recommendation", linked: false, completed: true)
      task_item_exists("Review Assessment", linked: true, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it is awaiting determination and recommendation has been reviewed" do
      planning_application = create(:planning_application, :awaiting_determination, local_authority: @default_local_authority)
      create(:recommendation, :reviewed, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: false, completed: true)
      task_item_exists("Submit Recommendation", linked: false, completed: true)
      task_item_exists("Review Assessment", linked: true, completed: true)
      task_item_exists("Publish", linked: true, completed: false)
    end

    it "makes valid task list for when it is determined" do
      planning_application = create(:planning_application, :determined, local_authority: @default_local_authority)
      create(:recommendation, :reviewed, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: false, completed: true)
      task_item_exists("Assess Proposal", linked: false, completed: true)
      task_item_exists("Submit Recommendation", linked: false, completed: true)
      task_item_exists("Review Assessment", linked: false, completed: true)
      task_item_exists("Publish", linked: false, completed: true)
    end

    it "makes valid task list for when it is awaiting correction and no re-proposal has been made" do
      planning_application = create(:planning_application, :awaiting_correction, local_authority: @default_local_authority)
      create(:recommendation, :reviewed, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: true, completed: false)
      task_item_exists("Submit Recommendation", linked: false, completed: false)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it is awaiting correction and a re-proposal has been made" do
      planning_application = create(:planning_application, :awaiting_correction, local_authority: @default_local_authority)
      create(:recommendation, :reviewed, planning_application: planning_application)
      create(:recommendation, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: true, completed: true)
      task_item_exists("Submit Recommendation", linked: true, completed: false)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
    end

    it "makes valid task list for when it is awaiting determination" do
      planning_application = create(:planning_application, :awaiting_determination, local_authority: @default_local_authority)
      create(:recommendation, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: false, completed: true)
      task_item_exists("Submit Recommendation", linked: false, completed: true)
      task_item_exists("Review Assessment", linked: false, completed: false)
      task_item_exists("Publish", linked: false, completed: false)
    end

    it "makes valid task list for when it is awaiting determination and recommendation has been reviewed" do
      planning_application = create(:planning_application, :awaiting_determination, local_authority: @default_local_authority)
      create(:recommendation, :reviewed, planning_application: planning_application)
      visit planning_application_path(planning_application.id)
      task_item_exists("Validate documents", linked: true, completed: true)
      task_item_exists("Assess Proposal", linked: false, completed: true)
      task_item_exists("Submit Recommendation", linked: false, completed: true)
      task_item_exists("Review Assessment", linked: false, completed: true)
      task_item_exists("Publish", linked: false, completed: false)
    end
  end

  def task_item_exists(text, opts = { linked: false, completed: false })
    within ".app-task-list__items" do
      within :xpath, "//*[contains(text(),'#{text}')]/ancestor::li[@class='app-task-list__item']" do
        if opts[:linked]
          expect(page).to have_link(text)
        else
          expect(page).not_to have_link(text)
        end
        if opts[:completed]
          expect(page).to have_content("Completed")
        else
          expect(page).not_to have_content("Completed")
        end
        if opts[:waiting]
          expect(page).to have_content("Waiting")
        else
          expect(page).not_to have_content("Waiting")
        end
      end
    end
  end
end
