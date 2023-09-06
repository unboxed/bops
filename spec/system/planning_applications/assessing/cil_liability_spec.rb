# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development right" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, old_constraints: [], local_authority: default_local_authority)
  end

  context "when signed in as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when planning application is in assessment" do
      it "is listed as incomplete by default" do
        visit planning_application_assessment_tasks_path(planning_application)

        within "#check-consistency-assessment-tasks" do
          expect(page).to have_content "CIL Liability Not started"
        end
      end

      it "can be marked as liable" do
        visit planning_application_assessment_tasks_path(planning_application)
        click_link "CIL Liability"
        choose "Yes"
        click_button "Save and mark as complete"

        expect(page).to have_content "CIL liability updated"
        within "#check-consistency-assessment-tasks" do
          expect(page).to have_content "CIL Liability Liable"
        end
      end

      it "can be marked as not liable" do
        visit planning_application_assessment_tasks_path(planning_application)
        click_link "CIL Liability"
        choose "No"
        click_button "Save and mark as complete"

        expect(page).to have_content "CIL liability updated"
        within "#check-consistency-assessment-tasks" do
          expect(page).to have_content "CIL Liability Not liable"
        end
      end

      context "when revisiting the edit page" do
        it "is marked as true when liable" do
          visit planning_application_assessment_tasks_path(planning_application)
          click_link "CIL Liability"
          choose "Yes"
          click_button "Save and mark as complete"

          click_link "CIL Liability"

          expect(find_by_id("planning-application-cil-liable-true-field")).to be_selected
          expect(find_by_id("planning-application-cil-liable-field")).not_to be_selected
        end

        it "is marked as false when not liable" do
          visit planning_application_assessment_tasks_path(planning_application)
          click_link "CIL Liability"
          choose "No"
          click_button "Save and mark as complete"

          click_link "CIL Liability"

          expect(find_by_id("planning-application-cil-liable-true-field")).not_to be_selected
          expect(find_by_id("planning-application-cil-liable-field")).to be_selected
        end
      end

      context "when there is no liability information from planx" do
        it "explains that there is no liability information" do
          visit planning_application_assessment_tasks_path(planning_application)
          click_link "CIL Liability"

          expect(page).to have_content("No information on potential CIL liability from PlanX.")
        end

        it "does not preselect any radio button" do
          visit planning_application_assessment_tasks_path(planning_application)
          click_link "CIL Liability"

          expect(find_by_id("planning-application-cil-liable-true-field")).not_to be_selected
          expect(find_by_id("planning-application-cil-liable-field")).not_to be_selected
        end
      end

      context "when there is liability information from planx" do
        before do
          cil_liability_proposal_detail = instance_double(ProposalDetail)
          allow(cil_liability_proposal_detail).to receive(:response_values).and_return([planx_response])
          allow_any_instance_of(PlanningApplication).to receive(:cil_liability_proposal_detail).and_return(cil_liability_proposal_detail)
        end

        context "when the application might be liable" do
          let(:planx_response) { "More than 100m²" }

          it "shows relevant liability information" do
            visit planning_application_assessment_tasks_path(planning_application)
            click_link "CIL Liability"

            expect(page).to have_content(planx_response)
            expect(page).to have_content("This might mean that the application is liable for CIL.")
          end

          it "selects yes by default" do
            visit planning_application_assessment_tasks_path(planning_application)
            click_link "CIL Liability"

            expect(find_by_id("planning-application-cil-liable-true-field")).not_to be_selected
            expect(find_by_id("planning-application-cil-liable-field")).not_to be_selected
          end
        end

        context "when the application might not be liable" do
          let(:planx_response) { "Less than 100m²" }

          it "shows relevant liability information" do
            visit planning_application_assessment_tasks_path(planning_application)
            click_link "CIL Liability"

            expect(page).to have_content(planx_response)
            expect(page).to have_content("This might mean that the application is not liable for CIL.")
          end

          it "selects no by default" do
            visit planning_application_assessment_tasks_path(planning_application)
            click_link "CIL Liability"

            expect(find_by_id("planning-application-cil-liable-true-field")).not_to be_selected
            expect(find_by_id("planning-application-cil-liable-field")).to be_selected
          end
        end
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit planning_application_path(planning_application)

      expect(page).not_to have_link("CIL Liability")

      visit edit_planning_application_cil_liability_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
