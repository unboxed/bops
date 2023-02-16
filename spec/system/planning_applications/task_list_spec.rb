# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "as a reviewer" do
    before do
      sign_in reviewer
    end

    it "makes valid task list for not_started" do
      planning_application = create(:planning_application, :not_started, local_authority: default_local_authority)
      visit planning_application_path(planning_application)

      within "#validation-section" do
        expect(page).to have_link("Check and validate")
        expect(page).not_to have_content("Completed")
      end

      within "#assess-section" do
        expect(page).not_to have_link("Check and assess")
      end
    end

    it "makes valid task list for when it has been validated but no proposal has been made" do
      planning_application = create(:planning_application, local_authority: default_local_authority)
      visit planning_application_path(planning_application)
      within "#validation-section" do
        expect(page).to have_link("Check and validate")
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).to have_link("Make draft recommendation")
        expect(list_item("Make draft recommendation")).not_to have_content("Completed")
        expect(page).not_to have_link("Review and submit recommendation")
      end
    end

    it "makes valid task list for when it in assessment and a proposal has been created" do
      planning_application = create(:planning_application, local_authority: default_local_authority)
      create(:recommendation, planning_application:, submitted: true)
      visit planning_application_path(planning_application)

      within "#assess-section" do
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).to have_link("Make draft recommendation")
        expect(list_item("Make draft recommendation")).to have_content("In progress")
        expect(page).to have_link("Review and submit recommendation")
      end
    end

    it "makes valid task list for when it is awaiting determination" do
      planning_application = create(:planning_application, :awaiting_determination,
                                    local_authority: default_local_authority)
      create(:recommendation, planning_application:)
      visit planning_application_path(planning_application)
      within "#validation-section" do
        expect(page).not_to have_link("Check and validate")
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).not_to have_link("Make draft recommendation")
        expect(page).to have_content("Completed")

        expect(page).not_to have_link("Review and submit recommendation")
        expect(page).to have_content("Completed")
      end

      visit planning_application_path(planning_application)

      within "#review-section" do
        expect(page).to have_link("Review and sign-off")
        expect(page).not_to have_content("Completed")

        expect(page).not_to have_link("Publish determination")
        expect(page).not_to have_content("Waiting")
      end
    end

    it "makes valid task list for when it is awaiting determination and recommendation has been reviewed" do
      planning_application = create(:planning_application, :awaiting_determination,
                                    local_authority: default_local_authority)
      create(:recommendation, :reviewed, planning_application:)
      visit planning_application_path(planning_application)

      within "#review-section" do
        expect(page).to have_link("Review and sign-off")
        expect(page).to have_content("Completed")
        expect(page).to have_link("Publish determination")
        within(:xpath, '//*[@id="review-section"]/ul/li[2]') do
          expect(page).not_to have_content("Completed")
        end
      end
    end

    it "makes valid task list for when it is awaiting correction and no re-proposal has been made" do
      planning_application = create(:planning_application, :awaiting_correction,
                                    local_authority: default_local_authority)

      create(
        :recommendation,
        :reviewed,
        planning_application:,
        challenged: true
      )

      visit planning_application_path(planning_application)

      within "#validation-section" do
        expect(page).to have_link("Check and validate")
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).to have_link("Make draft recommendation")
        expect(list_item("Make draft recommendation")).not_to have_content("Completed")
      end
    end

    it "makes valid task list for when it is awaiting correction and a re-proposal has been made" do
      planning_application = create(:planning_application, :awaiting_correction,
                                    local_authority: default_local_authority)
      create(:recommendation, :reviewed, planning_application:)
      create(:recommendation, planning_application:, submitted: true)
      visit planning_application_path(planning_application)

      within "#validation-section" do
        expect(page).to have_link("Check and validate")
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        expect(page).to have_link("Review non-validation requests")
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).to have_link("Make draft recommendation")
        expect(list_item("Make draft recommendation")).not_to have_content("Completed")
        expect(page).to have_content("Complete")
        expect(page).to have_link("Review and submit recommendation")
      end

      visit planning_application_path(planning_application)

      within "#assess-section" do
        expect(list_item("Check and assess")).to have_content("Completed")
      end
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
    end

    it "makes valid task list for when it is awaiting determination" do
      planning_application = create(:planning_application, :awaiting_determination,
                                    local_authority: default_local_authority)
      create(:recommendation, planning_application:)
      visit planning_application_path(planning_application)
      within "#validation-section" do
        expect(page).not_to have_link("Check and validate")
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        click_link "Check and assess"
      end

      within "#complete-assessment-tasks" do
        expect(page).not_to have_link("Review and submit recommendation")
        expect(page).to have_content("Completed")
      end

      visit planning_application_path(planning_application)

      within "#review-section" do
        expect(page).not_to have_link("Review and sign-off")
        expect(page).to have_link("View recommendation")
        expect(page).not_to have_content("Completed")

        expect(page).not_to have_link("Publish determination")
        expect(page).to have_content("Awaiting determination")
      end
    end

    it "makes valid task list for when it is awaiting determination and recommendation has been reviewed" do
      planning_application = create(:planning_application, :awaiting_determination,
                                    local_authority: default_local_authority)
      create(:recommendation, :reviewed, planning_application:)
      visit planning_application_path(planning_application)

      within "#validation-section" do
        expect(page).to have_content("Completed")
      end

      within "#assess-section" do
        expect(page).not_to have_link("Submit recommendation")
        expect(page).to have_content("Completed")
      end

      within "#review-section" do
        expect(page).not_to have_link("Review and sign-off")
        expect(page).to have_content("Completed")

        expect(page).not_to have_link("Publish determination")
        expect(page).to have_content("Waiting")
      end
    end
  end
end
