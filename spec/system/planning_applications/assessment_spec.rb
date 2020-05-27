# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  context "as an assessor" do
    let!(:planning_application) do
      create :planning_application,
             :lawfulness_certificate,
             reference: "19/AP/1880"
    end

    let(:policy_consideration_1) do
      create :policy_consideration,
            policy_question: "The property is",
            applicant_answer: "a semi detached house"
    end

    let(:policy_consideration_2) do
      create :policy_consideration,
            policy_question: "I want to",
            applicant_answer: "build new"
    end

    let!(:policy_evaluation) do
      create :policy_evaluation,
            planning_application: planning_application,
            policy_considerations: [policy_consideration_1, policy_consideration_2]
    end

    before do
      sign_in users(:assessor)
      visit root_path
    end

    scenario "Assessment completing and editing" do
      click_link "19/AP/1880"

      # Ensure we're starting from a fresh "checklist"
      expect(page).not_to have_css(".app-task-list__task-completed")

      # The second step is not yet a link
      expect(page).not_to have_link("Confirm recommendation")

      click_link "Evaluate permitted development policy requirements"

      expect(page).to have_content("The property is")
      expect(page).to have_content("a semi detached house")

      expect(page).to have_content("I want to")
      expect(page).to have_content("build new")

      choose "Yes"
      fill_in "comment_met", with: "This has been granted"

      click_button "Save"

      # TODO remove this line when we validate the comment_met in the decision notice
      expect(policy_evaluation.reload.comment_met).to eq("This has been granted")

      # Expect the 'completed' label to be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      click_link "Evaluate permitted development policy requirements"

      # Expect the saved state to be shown in the form
      within(find("form.policy_evaluation")) do
        expect(page.find_field("Yes")).to be_checked
      end

      choose "No"
      click_button "Save"

      # Expect the 'completed' label to still be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      click_link "Confirm recommendation"

      click_button "Submit to manager"

      within(:assessment_step, "Confirm recommendation") do
        expect(page).to have_completed_tag
      end

      click_link "Home"

      # Check that the application is no longer in assessment
      click_link "In assessment"

      within("#in_assessment") do
        expect(page).not_to have_link "19/AP/1880"
      end

      # Check that the application is now in awaiting determination
      click_link "Awaiting manager's determination"

      within("#awaiting_determination") do
        click_link "19/AP/1880"
      end

      expect(page).not_to have_link("Evaluate permitted development policy requirements")
      expect(page).not_to have_link("Confirm recommendation")
      # TODO: Continue this spec until the assessor decision has been made and check that policy evaluations can no longer be made
    end
  end

  context "as a reviewer" do
    # Look at an application that has had some assessment work done by the assessor
    let(:policy_evaluation) { create(:policy_evaluation, :met) }
    let(:assessor) { create :user, :assessor }
    let(:assessor_decision) { create :decision, user: assessor }
    let!(:planning_application) do
      create :planning_application,
       :awaiting_determination,
       policy_evaluation: policy_evaluation,
       assessor_decision: assessor_decision,
       reference: "19/AP/1880"
    end

    before do
      sign_in users(:reviewer)
      visit root_path
    end

    scenario "Assessment reviewing" do
      # Check that the application is no longer in awaiting determination
      within("#awaiting_determination") do
        click_link "19/AP/1880"
      end

      expect(page).not_to have_link("Evaluate permitted development policy requirements")

      expect(page).not_to have_link("Confirm recommendation")

      click_link "Review decision notice"
      choose "Yes"
      click_button "Save"

      expect(page).not_to have_link("Review decision notice")

      within(:assessment_step, "Review decision notice") do
        expect(page).to have_completed_tag
      end

      click_link "Home"

      # Check that the application is no longer in awaiting determination
      click_link "Awaiting manager's determination"
      within("#awaiting_determination") do
        expect(page).not_to have_link "19/AP/1880"
      end

      # Check that the application is now in determined
      click_link "Determined"
      within("#determined") do
        expect(page).to have_link "19/AP/1880"
      end
    end
  end

  context "as an admin" do
    let!(:planning_application) do
      create :planning_application, :with_policy_evaluation_requirements_unmet, reference: "19/AP/1880"
    end

    before do
      sign_in users(:admin)

      visit root_path
    end

    scenario "Assessment editing" do
      # TODO: Define admin actions on a planning application further and test them

      click_link "19/AP/1880"

      expect(page).to have_link "Evaluate permitted development policy requirements"

      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end
    end
  end
end
