# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
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

    before do
      sign_in users(:reviewer)
      visit root_path
    end

    context "with a granted assessor_decision without a comment" do
      let(:assessor_decision) { create :decision, :granted, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Publish and send decision notice")

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

        # TODO: Replace this with a check for state in the read-only determined decision
        # notice when we implement it
        planning_application = PlanningApplication.find_by(reference: "19/AP/1880")

        expect(planning_application.determined_at).to be_within(5.seconds).of(Time.current)
      end

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Publish and send decision notice")

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

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a granted assessor_decision with a comment" do
      let(:assessor_decision) { create :decision, :granted_with_comment, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Publish and send decision notice")

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

        expect(page).not_to have_link("Publish and send decision notice")

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

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision without a comment" do
      let(:assessor_decision) { create :decision, :refused, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Publish and send decision notice")

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

        expect(page).not_to have_link("Publish and send decision notice")

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

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision with a comment" do
      let(:assessor_decision) { create :decision, :refused_with_comment, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link "19/AP/1880"
        end

        expect(page).not_to have_link("Publish and send decision notice")

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

        expect(page).not_to have_link("Publish and send decision notice")

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

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end
  end

  context "as an admin" do
    let(:assessor) { create :user, :assessor }
    let(:assessor_decision) { create :decision, :granted, user: assessor }

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
