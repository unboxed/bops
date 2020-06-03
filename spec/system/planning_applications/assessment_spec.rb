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
             policy_question: "The project will ___ the internal floor area of the building",
             applicant_answer: "not alter"
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
      expect(page).not_to have_link("Confirm decision notice")

      within(".govuk-grid-column-two-thirds.application") do
        first('.govuk-accordion').click_button('Open all')
        expect(page).not_to have_text(users(:assessor).name)
      end

      # The assessor's name is not yet attached to the application
      expect(page).not_to have_text(users(:assessor).name)

      click_link "Evaluate permitted development policy requirements"

      expect(page).to have_content("The property is a semi detached house")
      expect(page).to have_content("The project will not alter the internal floor area of the building")

      expect(page).to have_text(users(:assessor).name)

      choose "Yes"
      fill_in "comment_met", with: "This has been granted"

      click_button "Save"

      # TODO remove this line when we validate the comment_met in the decision notice
      expect(planning_application.reload.assessor_decision.comment_met).to eq("This has been granted")

      # Expect the 'completed' label to be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      click_link "Evaluate permitted development policy requirements"

      # Expect the saved state to be shown in the form
      within(find("form.decision")) do
        expect(page.find_field("Yes")).to be_checked
      end

      choose "Yes"

      click_button "Save"

      # Expect the 'completed' label to still be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      click_link "Confirm decision notice"

      expect(page).to have_content("Submit Recommendation")
      expect(page).to have_content("Based on your answers given with the Permitted Development Policy Requirements, Permited Development should be #{planning_application.reload.assessor_decision.status}")

      expect(planning_application.reload.assessor_decision.comment_made?).to be(true)
      expect(page).to have_content("Your comments have been added to the decision notice.")

      expect(page).to have_content("Certificate of lawfulness of proposed use or development: #{planning_application.reload.assessor_decision.status}")

      # Applicant
      expect(page).to have_content("#{planning_application.applicant.full_name}")
      # Date of Issue of this decision, TODO: implement to hold the decided_at
      expect(page).to have_content("TBD")
      # Application received
      expect(page).to have_content("#{planning_application.created_at.strftime("%d/%m/%Y")}")
      # Address, TODO: add a fixture test for this
      # Application number
      expect(page).to have_content("#{planning_application.reference}")

      expect(page).to have_content("Certificate of lawful development (proposed) for the construction of #{planning_application.description}")

      click_button "Submit to manager"

      within(:assessment_step, "Confirm decision notice") do
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
      expect(page).not_to have_link("Confirm decision notice")
      # TODO: Continue this spec until the assessor decision has been made and check that policy evaluations can no longer be made
    end

    scenario "Assessor is assigned to planning application" do
      table_rows = all(".govuk-table__row").map(&:text)

      table_rows.each do |row|
        expect(row).to include("Not started") if row.include? "19/AP/1880"
      end

      click_link "19/AP/1880"

      # Ensure officer name is not displayed on page when accordion is opened
      within(".govuk-grid-column-two-thirds.application") do
        first('.govuk-accordion').click_button('Open all')
        expect(page).to have_text("Not started")
      end

      click_link "Evaluate permitted development policy requirements"

      # Ensure officer name is now displayed
      within(".govuk-grid-column-two-thirds.application") do
        expect(page).to have_text(users(:assessor).name)
      end

      click_link "Home"

      table_rows = all(".govuk-table__row").map(&:text)

      table_rows.each do |row|
        expect(row).to include(users(:assessor).name) if row.include? "19/AP/1880"
      end
    end
  end

  context "as a reviewer" do
    # Look at an application that has had some assessment work done by the assessor
    let(:policy_evaluation) { create(:policy_evaluation, :met) }
    let(:assessor) { create :user, :assessor }
    let!(:planning_application) do
      create :planning_application,
       :awaiting_determination,
       policy_evaluation: policy_evaluation,
       assessor_decision: assessor_decision,
       reference: "19/AP/1880"
    end

    before(:each) do
      sign_in users(:reviewer)
      visit root_path
    end

    context "with a granted assessor_decision without a comment" do
      let(:assessor_decision) { create :decision, :granted, user: assessor }

      scenario "Reviewer is not assigned to planning application" do
        click_link "19/AP/1880"

        click_link "Review permitted development policy requirements"

        click_link "Home"

        table_rows = all(".govuk-table__row").map(&:text)

        table_rows.each do |row|
          expect(row).not_to include(users(:reviewer).name) if row.include? "19/AP/1880"
        end
      end

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).not_to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).not_to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("refused")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

    context "with a granted assessor_decision with a comment" do
      let(:assessor_decision) { create :decision, :granted_with_comment, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).to have_content("The officer has submitted this comment to the applicant:")
        expect(page).to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("granted")
        expect(page).to have_content("Reason for granting:")
        expect(page).to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).to have_content("The officer has submitted this comment to the applicant:")
        expect(page).to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("refused")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

    context "with a refused assessor_decision without a comment" do
      let(:assessor_decision) { create :decision, :refused, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).not_to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("refused")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).not_to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

    context "with a refused assessor_decision with a comment" do
      let(:assessor_decision) { create :decision, :refused_with_comment, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("refused")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Confirm decision notice")

        click_link "Review permitted development policy requirements"

        expect(page).to have_content("The officer has submitted this comment to the applicant:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review permitted development policy requirements") do
          expect(page).to have_completed_tag
        end

        click_link "Review permitted development policy requirements"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish and send decision notice"

        expect(page).not_to have_content("Your comments have been added to the decision notice.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("Reason for granting:")
        expect(page).not_to have_content("This has been granted.")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish and send decision notice") do
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
  end

  context "as an admin" do
    let(:assessor) { create :user, :assessor }
    let(:assessor_decision) { create :decision, user: assessor }

    let!(:planning_application) do
      create :planning_application, reference: "19/AP/1880", assessor_decision: assessor_decision
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
